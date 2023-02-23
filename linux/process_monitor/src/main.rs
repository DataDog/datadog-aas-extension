use std::env;
use std::process::Command;

fn main() {
    let dd_command: Vec<String> = env::args().collect();
    let mut command = Command::new(&dd_command[0]);

    loop {
        if let Ok(mut dd_process) = command.spawn() {
            dd_process.wait().expect("dd_process wasn't running");
            println!("DataDog process {} has finished", dd_process.id())
        } else {
            println!("Datadog process did not start successfully")
        }
    }
}