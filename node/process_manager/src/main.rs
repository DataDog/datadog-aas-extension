use chrono::prelude::Utc;
use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::net::UdpSocket;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;

fn main() {
    let start_port = 8100;
    let end_port = 8200;

    if let Some(available_port) = (start_port..end_port).find(|port| port_is_available(*port)) {
        _ = write_log_to_file(&format!("Setting DD_DOGSTATSD_PORT to {}", available_port));
        env::set_var("DD_DOGSTATSD_PORT", &available_port.to_string());
    } else {
        _ = write_log_to_file(&format!(
            "No available ports in the range {} to {}. Setting DD_DOGSTATSD_PORT the default value of 8125",
            start_port, end_port
        ));
    }

    let mut threads = vec![];

    let tracing_enabled = env::var("DD_TRACE_ENABLED").unwrap_or("true".to_string()) == "true";
    let profiling_enabled =
        env::var("DD_PROFILING_ENABLED").unwrap_or("true".to_string()) == "true";

    if tracing_enabled || profiling_enabled {
        let trace_agent_thread = thread::spawn(|| {
            spawn_helper(
                "DD_TRACE_AGENT_PATH",
                "DD_TRACE_AGENT_ARGS",
                "datadog-trace-agent",
            );
        });
        threads.push(("datadog-trace-agent", trace_agent_thread));
    }

    if tracing_enabled {
        let dogstatsd_thread = thread::spawn(|| {
            spawn_helper("DD_DOGSTATSD_PATH", "DD_DOGSTATSD_ARGS", "dogstatsd");
        });
        threads.push(("dogstatsd", dogstatsd_thread))
    }

    for (process_name, thread) in threads {
        thread
            .join()
            .expect(&format!("{} thread panicked", process_name));
    }
}

/// Writes the `log_message` to the file at `file_path`.
fn write_log_to_file(log_message: &str) -> std::io::Result<()> {
    let log_file_path =
        "/home/LogFiles/datadog/Datadog.AzureAppServices.Node.Apm-process_manager.txt";
    let log_path = PathBuf::from(log_file_path);

    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .append(true)
        .open(log_path)?;

    let formatted_timestamp = Utc::now().format("%Y-%m-%dT%H:%M:%S").to_string();
    let extension_version = env::var("DD_AAS_EXTENSION_VERSION").unwrap();

    let formatted_log = format!(
        "{} [{}] {}\n",
        formatted_timestamp, extension_version, log_message
    );

    file.write_all(formatted_log.as_bytes())?;
    Ok(())
}

fn port_is_available(port: u16) -> bool {
    match UdpSocket::bind(("127.0.0.1", port)) {
        Ok(_) => true,
        Err(_) => false,
    }
}

/// Creates a `Command` that will execute the DD process. The path to the
/// process and it's arguments are the values of the environment variables
/// `path_var` and `args_var`.
fn spawn_helper(path_var: &str, args_var: &str, process_name: &str) {
    if env::var("DD_API_KEY").is_err() {
        _ = write_log_to_file(&format!(
            "Cannot start {}, DD_API_KEY not provided",
            process_name
        ));
        return;
    }

    if let Ok(process_path) = env::var(path_var) {
        let path = Path::new(&process_path);
        if !path.exists() {
            _ = write_log_to_file(&format!(
                "Cannot start {}, invalid path '{}' provided",
                process_name, process_path
            ));
            return;
        }

        let mut dd_command = Command::new(process_path);

        if let Ok(process_args) = env::var(args_var) {
            dd_command.args(process_args.split(" "));
            spawn(dd_command, process_name);
        } else {
            _ = write_log_to_file(&format!(
                "Cannot start {}, {} not provided",
                process_name, args_var
            ));
        }
    } else {
        _ = write_log_to_file(&format!(
            "Cannot start {}, {} not provided",
            process_name, path_var
        ));
    }
}

/// Executes `command` and re-launches it if it has a non-zero exit.
fn spawn(mut command: Command, process_name: &str) {
    if let Ok(mut dd_process) = command.spawn() {
        let status = dd_process.wait().expect("dd_process wasn't running");
        _ = write_log_to_file(&format!(
            "{} has finished with status: {}",
            process_name, status
        ));
        if !status.success() {
            spawn(command, process_name);
        }
    } else {
        _ = write_log_to_file(&format!("{} did not start successfully", process_name));
    }
}
