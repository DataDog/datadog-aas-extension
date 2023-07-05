#define _WINSOCKAPI_
#include <windows.h>
#include <sal.h>
#include <httpserv.h>
#include <iostream>
#include <fstream>
#include <string>

class AgentProcessManager : public CGlobalModule
{
public:
    GLOBAL_NOTIFICATION_STATUS OnGlobalApplicationResolveModules(IN IHttpApplicationResolveModulesProvider* pProvider)
    {
        UNREFERENCED_PARAMETER(pProvider);
        StartAgent();
        return GL_NOTIFICATION_CONTINUE;
    }

    VOID Terminate()
    {
        delete this;
    }

private:
    int StartAgent() {
        STARTUPINFO si;
        PROCESS_INFORMATION pi;
        SECURITY_ATTRIBUTES sa;

        sa.nLength = sizeof(sa);
        sa.lpSecurityDescriptor = NULL;
        sa.bInheritHandle = TRUE;

        HANDLE hOutput = CreateFile(
            L"C:\\home\\trace_agent_log.txt", 
            FILE_APPEND_DATA,
            FILE_SHARE_WRITE | FILE_SHARE_READ,
            &sa,
            OPEN_ALWAYS,
            FILE_ATTRIBUTE_NORMAL,
            NULL
        );

        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        si.dwFlags |= STARTF_USESTDHANDLES;
        si.hStdOutput = hOutput;
        si.hStdError = hOutput;

        ZeroMemory(&pi, sizeof(pi));

        WCHAR cmd[] = L"/home/SiteExtensions/content/process_manager.exe /home/SiteExtensions/content/Agent/trace-agent.exe";

        if (!CreateProcess(
            NULL,       // No module name (use command line)
            cmd,        // Command line
            NULL,       // Process handle not inheritable
            NULL,       // Thread handle not inheritable
            TRUE,       // Set handle inheritance to TRUE for output redirect
            0,          // No creation flags
            NULL,       // Use parent's environment block
            NULL,       // Use parent's starting directory
            &si,        // Pointer to STARTUPINFO structure
            &pi)        // Pointer to PROCESS_INFORMATION structure
            )
        {
            std::wstring errorMessage = L"CreateProcess failed (" + std::to_wstring(GetLastError()) + L").\n";

            WriteLog(errorMessage.c_str());
            return 1;
        } else {
            WriteLog(L"CreateProcess succeeded");
        }

        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        CloseHandle(hOutput);

        return 0;
    }

    void WriteLog(LPCWSTR szNotification)
    {
        std::wofstream logFile;
        logFile.open("C:\\home\\IIS_module_log.txt", std::ios_base::app);
        logFile << szNotification << std::endl;
        logFile.close();
    }
};

HRESULT
__stdcall
RegisterModule(
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

    return pModuleInfo->SetGlobalNotifications(pGlobalModule, GL_APPLICATION_RESOLVE_MODULES);
}