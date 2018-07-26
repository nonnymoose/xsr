void setup_signal_handler();
extern sigset_t global_signal_mask;
extern pthread_t signal_handler_thread; // I didn't want to make this global at first but I might want it later
extern std::atomic<bool> exit_cleanly;
