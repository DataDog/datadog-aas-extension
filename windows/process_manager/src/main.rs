use std::env;
use std::net::TcpListener;
use std::process::Command;
use std::thread;

fn main() {
    // If we're in Node, dynamically set the DOGSTATSD socket
    if env::var("WEBSITE_NODE_DEFAULT_VERSION").is_some() {
        // TODO: fetch these from env var?
        let start_port = 8100;
        let end_port = 8200;

        if let Some(free_port) = find_free_port(start_port, end_port) {
            env::set_var("DD_DOGSTATSD_HOSTNAME", "localhost");
            env::set_var("DD_DOGSTATSD_PORT", free_port.to_string());
            env::remove_var("DD_AGENT_PIPE_NAME");
            env::remove_var("DD_DOGSTATSD_PIPE_NAME");
            env::remove_var("DD_DOGSTATSD_WINDOWS_PIPE_NAME");
        } else {
            println!("Cannot spawn dogstatsd, no free ports in range {}-{}", start_port, end_port);
            return;
        }
    }

    let trace_agent_thread = thread::spawn(|| {
        spawn_helper("DD_TRACE_AGENT_PATH", "DD_TRACE_AGENT_ARGS", "trace-agent");
    });

    let dogstatsd_thread = thread::spawn(|| {
        spawn_helper("DD_DOGSTATSD_PATH", "DD_DOGSTATSD_ARGS", "dogstatsd");
    });

    // Wait for both threads to complete
    trace_agent_thread.join().expect("trace-agent thread panicked");
    dogstatsd_thread.join().expect("dogstatsd thread panicked");
}

fn find_free_port(start_port: u16, end_port: u16) -> Option<u16> {
    for port in start_port..=end_port {
        if TcpListener::bind(("127.0.0.1", port)).is_ok() {
            return Some(port);
        }
    }
    None
}

fn spawn_helper(path_var: &str, args_var: &str, process_name: &str) {
    if let Ok(agent_path) = env::var(path_var) {
        let mut dd_command = Command::new(agent_path);

        if let Ok(agent_args) = env::var(args_var) {
            dd_command.args(agent_args.split(" "));
            spawn(dd_command)
        } else {
            println!("Cannot spawn {}, {} not provided", process_name, path_var)
        }
    } else {
        println!("Cannot spawn {}, {} not provided", process_name, path_var)
    }
}

fn spawn(mut command: Command) {
    if let Ok(mut dd_process) = command.spawn() {
        let status = dd_process.wait().expect("dd_process wasn't running");
        println!("DataDog process {} has finished", status);
        if !status.success() {
            spawn(command);
        }
    } else {
        println!("Datadog process did not start successfully");
    }
}
