#define _WINSOCKAPI_

#include <algorithm>
#include <codecvt>
#include <ctime>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <locale>
#include <mutex>
#include <sstream>
#include <string>

#include <windows.h>
#include <tlhelp32.h>

#include <httpserv.h>
#include <sal.h>

class AgentProcessManager : public CGlobalModule
{
public:
    GLOBAL_NOTIFICATION_STATUS OnGlobalApplicationResolveModules(IN IHttpApplicationResolveModulesProvider *pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        StartAgent(L"trace-agent");
        StartAgent(L"dogstatsd");
        return GL_NOTIFICATION_CONTINUE;
    }

    GLOBAL_NOTIFICATION_STATUS OnGlobalApplicationStart(IN IHttpApplicationStartProvider *pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        StartAgent(L"trace-agent");
        StartAgent(L"dogstatsd");
        return GL_NOTIFICATION_CONTINUE;
    }

    GLOBAL_NOTIFICATION_STATUS OnGlobalPreBeginRequest(IN IPreBeginRequestProvider *pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        if (!ProcessExists("trace-agent"))
        {
            StartAgent(L"trace-agent");
        }
        if (!ProcessExists("dogstatsd"))
        {
            StartAgent(L"dogstatsd");
        }
        return GL_NOTIFICATION_CONTINUE;
    }

    VOID Terminate()
    {
        delete this;
    }

    int GetRuntime()
    {
        if (!GetEnvironmentVariableAsString(L"WEBSITE_STACK").empty())
        {
            // Java
            return 0;
        }
        else if (!GetEnvironmentVariableAsString(L"WEBSITE_NODE_DEFAULT_VERSION").empty())
        {
            // Node
            return 1;
        }

        // .NET
        return 2;
    }

private:
    int StartAgent(const std::wstring &agentName)
    {
        STARTUPINFO si;
        PROCESS_INFORMATION pi;

        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);

        ZeroMemory(&pi, sizeof(pi));

        std::wstring versionDir = GetEnvironmentVariableAsString(L"DD_AAS_EXTENSION_VERSION");
        std::replace(versionDir.begin(), versionDir.end(), L'.', L'_');

        std::wstring cmd = L"/home/SiteExtensions/DevelopmentVerification.DdWindows.Apm/process_manager /home/SiteExtensions/DevelopmentVerification.DdWindows.Apm/" + versionDir + L"/Agent/" + agentName;

        if (!CreateProcess(NULL, const_cast<LPWSTR>(cmd.c_str()), NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))
        {
            std::wstring errorMessage = L"Start " + agentName + L" failed (" + std::to_wstring(GetLastError()) + L").\n";
            WriteLog(errorMessage.c_str());
            return 1;
        }
        else
        {
            std::wstring successMessage = L"Start " + agentName + L" succeeded";
            WriteLog(successMessage.c_str());
        }

        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        CloseHandle(hOutput);

        return 0;
    }

    std::wstring GetEnvironmentVariableAsString(const std::wstring &name)
    {
        DWORD bufferLength = ::GetEnvironmentVariableW(name.c_str(), NULL, 0);
        if (bufferLength == 0)
        {
            return std::wstring();
        }

        std::wstring buffer;
        buffer.resize(bufferLength);
        ::GetEnvironmentVariableW(name.c_str(), &buffer[0], bufferLength);

        buffer.erase(std::remove(buffer.begin(), buffer.end(), L'\0'), buffer.end());

        return buffer;
    }

    bool ProcessExists(const std::string &processName)
    {
        PROCESSENTRY32 entry;
        entry.dwSize = sizeof(PROCESSENTRY32);

        HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);

        if (Process32First(snapshot, &entry))
        {
            while (Process32Next(snapshot, &entry))
            {
                if (_stricmp(ConvertWCharToStdString(entry.szExeFile).c_str(), (processName + ".exe").c_str()) == 0)
                {
                    CloseHandle(snapshot);
                    return TRUE;
                }
            }
        }

        CloseHandle(snapshot);
        return FALSE;
    }

    std::string ConvertWCharToStdString(const WCHAR *wstr)
    {
        std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
        std::wstring wide(wstr);
        return converter.to_bytes(wide);
    }

    std::string ConvertWStringToString(const std::wstring &wideStr)
    {
        std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
        return converter.to_bytes(wideStr);
    }

    void WriteLog(LPCWSTR szNotification)
    {
        std::wofstream logFile("/home/LogFiles/datadog/Datadog.AzureAppServices.Windows-Install.txt", std::ios_base::app);

        logFile << GetCurrentTimestamp() << " [" << GetEnvironmentVariableAsString(L"DD_AAS_EXTENSION_VERSION") << "] " << szNotification << std::endl;

        logFile.close();
    }

    std::wstring GetCurrentTimestamp()
    {
        std::time_t now = std::time(nullptr);
        std::tm localTime;
        localtime_s(&localTime, &now);

        std::wostringstream oss;
        oss << std::put_time(&localTime, L"%a %m/%d/%Y %H:%M:%S") << L'.' <<
            std::setw(2) << std::setfill(L'0') << std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count() % 1000;

        return oss.str();
    }
};

HRESULT
__stdcall RegisterModule(
    DWORD dwServerVersion,
    IHttpModuleRegistrationInfo *pModuleInfo,
    IHttpServer *pGlobalInfo)
{
    UNREFERENCED_PARAMETER(dwServerVersion);
    UNREFERENCED_PARAMETER(pGlobalInfo);

    AgentProcessManager *pGlobalModule = new AgentProcessManager;

    if (NULL == pGlobalModule)
    {
        return HRESULT_FROM_WIN32(ERROR_NOT_ENOUGH_MEMORY);
    }

    int runtime = pGlobalModule->GetRuntime();

    if (runtime == 0)
    {
        return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_APPLICATION_START);
    }
    else if (runtime == 1)
    {
        return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_APPLICATION_RESOLVE_MODULES);
    }

    return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_PRE_BEGIN_REQUEST);
}