defmodule GitHubWorkflows do
  @moduledoc """
  Used by a custom tool to generate GitHub workflows.
  Reduces repetition.
  """

  def get do
    %{
      "cd.yml" => cd_workflow()
    }
  end

  defp cd_workflow do
    [
      [
        name: "CD",
        on: [:push, :workflow_dispatch],
        jobs: [
          deploy: deploy_job()
        ]
      ]
    ]
  end

  defp deploy_job do
    [
      name: "Deploy to Fly.io",
      if: "github.event_name != 'pull_request'",
      "runs-on": "ubuntu-latest",
      env: [
        FLY_API_TOKEN: "${{ secrets.FLY_API_TOKEN }}"
      ],
      steps: [
        [
          uses: "actions/checkout@v2"
        ],
        [
          uses: "superfly/flyctl-actions@1.1",
          with: [
            args: "deploy"
          ]
        ]
      ]
    ]
  end
end
