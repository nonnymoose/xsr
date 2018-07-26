// #include <thread>
#include <pthread.h> // I would use std::thread but there's no support for catching signals
#include <csignal>
#include <atomic> // I hope it's ok to mix std::atomic with pthread
#include "signal_handler.h"

sigset_t global_signal_mask;
pthread_t signal_handler_thread; // I didn't want to make this global at first but I might want it later
std::atomic<bool> exit_cleanly (false);

void* signal_handler(void *) {
	int unused;
	sigwait(&global_signal_mask, &unused); // we know that we only need to trap one type of signal: clean exit
	exit_cleanly.store(true);
	return 0;
}

void setup_signal_handler() {
	sigemptyset(&global_signal_mask);
	sigaddset(&global_signal_mask, SIGHUP);
	sigaddset(&global_signal_mask, SIGINT);
	// sigaddset(&global_signal_mask, SIGQUIT); // if the user wants us to die that much, we should just let them kill us. It's probably our fault.
	sigaddset(&global_signal_mask, SIGPIPE); // stubbornly write out anyway
	sigaddset(&global_signal_mask, SIGALRM);
	sigaddset(&global_signal_mask, SIGTERM);
	pthread_sigmask(SIG_BLOCK, &global_signal_mask, NULL);
	pthread_create(&signal_handler_thread, NULL, signal_handler, NULL);
}
