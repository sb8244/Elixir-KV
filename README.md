KV
==

This code follows the large multi-concept tutorial from Elixir docs. You can find
the documentation [here](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

The code mostly follows the tutorial, with a few improvements around registry testing.

# Supervision Tree

The tree holds two different branches: the socket server and the KV bucket server.

![image](https://cloud.githubusercontent.com/assets/1231659/17655574/defa4e24-627d-11e6-814b-a5a308767045.png)

Once connected, a process is started for each client. This tree has 2 processes attached to the KV.Server.TaskSupervisor:

![image](https://cloud.githubusercontent.com/assets/1231659/17655593/1155c646-627e-11e6-8030-073f0d9b50f3.png)

Each bucket created is stored as a process, so that each bucket is independent from the others. Here are
3 buckets created:

![image](https://cloud.githubusercontent.com/assets/1231659/17655604/3302c03c-627e-11e6-8b66-137c742ab516.png)

Each client is able to communicate with any bucket created by others due to the state
existing outside of their client process.
