defmodule KV.Server.Supervisor do
  def start_link do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: KV.Server.TaskSupervisor]]),
      worker(Task, [KV.Server, :accept, [5050]])
    ]

    opts = [strategy: :one_for_one, name: KV.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
