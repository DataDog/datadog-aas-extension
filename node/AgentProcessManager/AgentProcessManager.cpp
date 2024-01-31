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

std::wstring convertPath(const std::wstring& windowsPath) {
    std::wstring unixPath = windowsPath;

    // Remove drive letter prefix if present
    size_t pos = unixPath.find(L":");
    if (pos != std::wstring::npos) {
        unixPath.erase(0, pos + 1);
    }

    // Replace backslashes with forward slashes
    std::replace(unixPath.begin(), unixPath.end(), L'\\', L'/');

    return unixPath;
}

class AgentProcessManager : public CGlobalModule
{
public:
    GLOBAL_NOTIFICATION_STATUS OnGlobalApplicationResolveModules(IN IHttpApplicationResolveModulesProvider* pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        StartAgents();
        return GL_NOTIFICATION_CONTINUE;
    }

    GLOBAL_NOTIFICATION_STATUS OnGlobalApplicationStart(IN IHttpApplicationStartProvider* pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        StartAgents();
        return GL_NOTIFICATION_CONTINUE;
    }

    GLOBAL_NOTIFICATION_STATUS OnGlobalPreBeginRequest(IN IPreBeginRequestProvider* pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        if (!ProcessExists("process_manager"))
        {
            HANDLE hMutex = CreateMutex(NULL, TRUE, L"process_manager");
            if (hMutex != NULL && GetLastError() != ERROR_ALREADY_EXISTS)
            {
                StartAgents();
                CloseHandle(hMutex);
            }
        }
        return GL_NOTIFICATION_CONTINUE;
    }

    VOID Terminate()
    {
        delete this;
    }

private:
    int StartAgents()
    {
        STARTUPINFO si;
        PROCESS_INFORMATION pi;

        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);

        ZeroMemory(&pi, sizeof(pi));

        std::wstring windowsPath = GetEnvironmentVariableAsString(L"DD_EXTENSION_PATH").c_str();
        std::wstring unixPath = convertPath(windowsPath).c_str();
        std::wstring cmd = unixPath + L"/process_manager";

        if (!CreateProcess(NULL, const_cast<LPWSTR>(cmd.c_str()), NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))
        {
            std::wstring errorMessage = L"Start process_manager failed (" + std::to_wstring(GetLastError()) + L").\n";
            WriteLog(errorMessage.c_str());
            return 1;
        }
        else
        {
            std::wstring successMessage = L"Start process_manager succeeded";
            WriteLog(successMessage.c_str());
        }

        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);

        return 0;
    }

    std::wstring GetEnvironmentVariableAsString(const std::wstring& name)
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

    bool ProcessExists(const std::string& processName)
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

    std::string ConvertWCharToStdString(const WCHAR* wstr)
    {
        std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
        std::wstring wide(wstr);
        return converter.to_bytes(wide);
    }

    void WriteLog(LPCWSTR szNotification)
    {
        std::wstring runtime = GetEnvironmentVariableAsString(L"DD_RUNTIME").c_str();
        std::wofstream logFile(L"/home/LogFiles/datadog/Datadog.AzureAppServices." + runtime + L".Apm.txt", std::ios_base::app);

        logFile << GetCurrentTimestamp() << " [" << GetEnvironmentVariableAsString(L"DD_AAS_EXTENSION_VERSION") << "] " << szNotification << std::endl;

        logFile.close();
    }

    std::wstring GetCurrentTimestamp()
    {
        std::time_t now = std::time(nullptr);
        std::tm localTime;
        localtime_s(&localTime, &now);

        std::wostringstream oss;
        oss << std::put_time(&localTime, L"%a %m/%d/%Y %H:%M:%S") <<
            L'.' << std::setw(2) << std::setfill(L'0') <<
            std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count() % 1000;

        return oss.str();
    }
};

HRESULT
__stdcall RegisterModule(
    DWORD dwServerVersion,
    IHttpModuleRegistrationInfo* pModuleInfo,
    IHttpServer* pGlobalInfo)
{
    UNREFERENCED_PARAMETER(dwServerVersion);
    UNREFERENCED_PARAMETER(pGlobalInfo);

    AgentProcessManager* pGlobalModule = new AgentProcessManager;

    if (NULL == pGlobalModule)
    {
        return HRESULT_FROM_WIN32(ERROR_NOT_ENOUGH_MEMORY);
    }

    return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_PRE_BEGIN_REQUEST);
}
