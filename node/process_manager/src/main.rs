use chrono::prelude::Utc;
use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::net::UdpSocket;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;

fn main() {
    set_dogstatsd_port();

    let mut threads = vec![];

    let tracing_enabled = env::var("DD_TRACE_ENABLED").unwrap_or("true".to_string()) == "true";
    let profiling_enabled =
        env::var("DD_PROFILING_ENABLED").unwrap_or("true".to_string()) == "true";

    if tracing_enabled || profiling_enabled {
        let trace_agent_thread = thread::spawn(|| {
            if let Err(err) = spawn_helper(
                "DD_TRACE_AGENT_PATH",
                "DD_TRACE_AGENT_ARGS",
                "datadog-trace-agent",
            ) {
                let log_message = format!("Error starting trace agent: {}", err);
                write_log_to_file(&log_message);
            }
        });
        threads.push(("datadog-trace-agent", trace_agent_thread));
    }

    if tracing_enabled {
        let dogstatsd_thread = thread::spawn(|| {
            if let Err(err) = spawn_helper("DD_DOGSTATSD_PATH", "DD_DOGSTATSD_ARGS", "dogstatsd") {
                let log_message = format!("Error starting dogstatsd agent: {}", err);
                write_log_to_file(&log_message);
            }
        });
        threads.push(("dogstatsd", dogstatsd_thread))
    }

    for (process_name, thread) in threads {
        thread
            .join()
            .unwrap_or_else(|_| panic!("{} thread panicked", process_name));
    }
}

/// Writes the `log_message` to the file at `file_path`.
fn write_log_to_file(log_message: &str) {
    let log_file_path =
        "/home/LogFiles/datadog/Datadog.AzureAppServices.Node.Apm-process_manager.txt";
    let log_path = PathBuf::from(log_file_path);

    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .write(true)
        .append(true)
        .open(log_path)
    {
        let formatted_timestamp = Utc::now().format("%Y-%m-%dT%H:%M:%S").to_string();
        let extension_version = env::var("DD_AAS_EXTENSION_VERSION").unwrap_or_default();

        let formatted_log = format!(
            "{} [{}] {}\n",
            formatted_timestamp, extension_version, log_message
        );

        file.write_all(formatted_log.as_bytes()).unwrap_or_default();
    }
}

/// Creates a `Command` that will execute the DD process. The path to the
/// process and it's arguments are the values of the environment variables
/// `path_var` and `args_var`.
fn spawn_helper(path_var: &str, args_var: &str, process_name: &str) -> Result<bool, String> {
    env::var("DD_API_KEY").map_err(|_| "DD_API_KEY not provided".to_string())?;

    if let Ok(process_path) = env::var(path_var) {
        let path = Path::new(&process_path);
        if !path.exists() {
            let message = format!("Invalid path provided '{}", process_path);
            return Err(message);
        }

        let mut dd_command = Command::new(process_path);

        if let Ok(process_args) = env::var(args_var) {
            dd_command.args(process_args.split(' '));
            spawn(dd_command, process_name);
        } else {
            let message = format!("{} not provided", args_var);
            return Err(message);
        }
    } else {
        let message = format!("{} not provided", path_var);
        return Err(message);
    }

    Ok(true)
}

/// Executes `command` and re-launches it if it has a non-zero exit.
fn spawn(mut command: Command, process_name: &str) {
    if let Ok(mut dd_process) = command.spawn() {
        let status = dd_process.wait().expect("dd_process wasn't running");
        write_log_to_file(&format!(
            "{} has finished with status: {}",
            process_name, status
        ));
        if !status.success() {
            spawn(command, process_name);
        }
    } else {
        write_log_to_file(&format!("{} did not start successfully", process_name));
    }
}

fn set_dogstatsd_port() {
    let start_port = 8100;
    let end_port = 8200;

    if let Some(available_port) =
        (start_port..end_port).find(|port| UdpSocket::bind(("127.0.0.1", *port)).is_ok())
    {
        write_log_to_file(&format!("Setting DD_DOGSTATSD_PORT to {}", available_port));
        env::set_var("DD_DOGSTATSD_PORT", available_port.to_string());
    } else {
        write_log_to_file(&format!(
            "No available ports in the range {} to {}. Using the default DD_DOGSTATSD_PORT value",
            start_port, end_port
        ));
    }
}
