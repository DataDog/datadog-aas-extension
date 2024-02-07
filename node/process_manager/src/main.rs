use chrono::prelude::*;
use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::net::TcpListener;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;

fn main() {
    // If we're in Node, dynamically set the DOGSTATSD port
    if env::var("WEBSITE_NODE_DEFAULT_VERSION").is_ok() {
        // TODO: find a better range
        let start_port = 8100;
        let end_port = 8200;

        if let Some(free_port) = find_free_port(start_port, end_port) {
            env::set_var("DD_DOGSTATSD_PORT", free_port.to_string());
        } else {
            _ = write_log_to_file(&format!("Cannot start dogstatsd, no free ports in range {}-{}", start_port, end_port));
            return;
        }
    }

    let mut threads = vec![];

    let tracing_enabled = env::var("DD_TRACE_ENABLED").unwrap_or("true".to_string()) == "true";
    let profiling_enabled = env::var("DD_PROFILING_ENABLED").unwrap_or("true".to_string()) == "true";
    
    if tracing_enabled || profiling_enabled {
        let trace_agent_thread = thread::spawn(|| {
            spawn_helper("DD_TRACE_AGENT_PATH", "DD_TRACE_AGENT_ARGS", "trace-agent");
        });
        threads.push(("trace-agent", trace_agent_thread));
    }

    if tracing_enabled {
        let dogstatsd_thread = thread::spawn(|| {
            spawn_helper("DD_DOGSTATSD_PATH", "DD_DOGSTATSD_ARGS", "dogstatsd");
        });
        threads.push(("dogstatsd", dogstatsd_thread))
    }

    for (process_name, thread) in threads {
        thread.join().expect(&format!("{} thread panicked", process_name));
    }
}

/// Writes the `log_message` to the file at `file_path`.
fn write_log_to_file(log_message: &str) -> std::io::Result<()> {
    let log_file_path = format!("/home/LogFiles/datadog/Datadog.AzureAppServices.{}.Apm.txt", env::var("DD_RUNTIME").unwrap());
    let log_path = PathBuf::from(log_file_path);

    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .append(true)
        .open(log_path)?;

    let timestamp = Local::now();
    let formatted_timestamp = timestamp.format("%a %m/%d/%Y %H:%M:%S%.2f");
    let extension_version = env::var("DD_AAS_EXTENSION_VERSION").unwrap();

    let formatted_log = format!("{} [{}] {}\n", formatted_timestamp, extension_version, log_message);

    file.write_all(formatted_log.as_bytes())?;
    Ok(())
}

/// Yields a free port between `start_port` and `end_port` if any exist.
fn find_free_port(start_port: u16, end_port: u16) -> Option<u16> {
    for port in start_port..=end_port {
        if TcpListener::bind(("127.0.0.1", port)).is_ok() {
            return Some(port);
        }
    }
    None
}

/// Creates a `Command` that will execute the DD process. The path to the
/// process and it's arguments are the values of the environment variables
/// `path_var` and `args_var`.
fn spawn_helper(path_var: &str, args_var: &str, process_name: &str) {
    if env::var("DD_API_KEY").is_err() {
        _ = write_log_to_file(&format!("Cannot start {}, DD_API_KEY not provided", process_name));
        return;
    }

    if let Ok(process_path) = env::var(path_var) {
        let path = Path::new(&process_path);
        if !path.exists() {
            _ = write_log_to_file(&format!("Cannot start {}, invalid path '{}' provided", process_name, process_path));
            return;
        }

        let mut dd_command = Command::new(process_path);

        if let Ok(process_args) = env::var(args_var) {
            dd_command.args(process_args.split(" "));
            spawn(dd_command, process_name);
        } else {
            _ = write_log_to_file(&format!("Cannot start {}, {} not provided", process_name, args_var));
        }
    } else {
        _ = write_log_to_file(&format!("Cannot start {}, {} not provided", process_name, path_var));
    }
}

/// Executes `command` and re-launches it if it has a non-zero exit.
fn spawn(mut command: Command, process_name: &str) {
    if let Ok(mut dd_process) = command.spawn() {
        let status = dd_process.wait().expect("dd_process wasn't running");
        _ = write_log_to_file(&format!("{} has finished with status: {}", process_name, status));
        if !status.success() {
            spawn(command, process_name);
        }
    } else {
        _ = write_log_to_file(&format!("{} did not start successfully", process_name));
    }
}
