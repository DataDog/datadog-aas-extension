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
    GLOBAL_NOTIFICATION_STATUS OnGlobalPreBeginRequest(IN IPreBeginRequestProvider *pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        if (!ProcessExists(L"process_manager.exe"))
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
    void StartAgents()
    {
        STARTUPINFO si;
        PROCESS_INFORMATION pi;

        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        ZeroMemory(&pi, sizeof(pi));

        std::wstring extensionPath = GetEnvironmentVariableAsString(L"DD_EXTENSION_PATH");
        std::wstring cmd = extensionPath + L"\\process_manager";

        if (!CreateProcess(NULL, const_cast<LPWSTR>(cmd.c_str()), NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi))
        {
            std::wstring errorMessage = L"Start process_manager failed (" + std::to_wstring(GetLastError()) + L")";
            WriteLog(errorMessage.c_str());
        }
        else
        {
            WriteLog(L"Start process_manager succeeded");
        }

        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
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

    bool ProcessExists(const std::wstring &processName)
    {
        HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (hSnap == INVALID_HANDLE_VALUE)
        {
            WriteLog(L"Failed to create snapshot while checking for process_manager.exe");
            return false;
        }

        PROCESSENTRY32 entry;
        entry.dwSize = sizeof(entry);

        if (!Process32First(hSnap, &entry))
        {
            CloseHandle(hSnap);
            WriteLog(L"Failed to get first process while checking for process_manager.exe");
            return false;
        }

        do
        {
            if (processName == std::wstring(entry.szExeFile))
            {
                CloseHandle(hSnap);
                return true;
            }
        } while (Process32Next(hSnap, &entry));

        CloseHandle(hSnap);
        return false;
    }

    void WriteLog(LPCWSTR szNotification)
    {
        std::wofstream logFile(L"/home/LogFiles/datadog/Datadog.AzureAppServices.Node.Apm-AgentProcessManagerModule.txt", std::ios_base::app);

        logFile << GetCurrentTimestamp() << " [" << GetEnvironmentVariableAsString(L"DD_AAS_EXTENSION_VERSION") << "] " << szNotification << std::endl;

        logFile.close();
    }

    std::wstring GetCurrentTimestamp()
    {
        std::time_t now = std::time(nullptr);
        std::tm timeinfo;
        gmtime_s(&timeinfo, &now);

        std::wostringstream oss;
        oss << std::put_time(&timeinfo, L"%Y-%m-%dT%H:%M:%S");

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

    return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_PRE_BEGIN_REQUEST);
}
