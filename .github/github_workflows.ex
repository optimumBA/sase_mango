defmodule GitHubWorkflows do
  @moduledoc """
  Used by a custom tool to generate GitHub workflows.
  Reduces repetition.
  """

  def get do
    %{
      "main.yml" => main_workflow()
    }
  end

  defp main_workflow do
    [
      [
        name: "Main",
        on: [
          push: [
            branches: ["main"]
          ]
        ],
        jobs: [
          deploy: deploy_job()
        ]
      ]
    ]
  end

  defp deploy_job do
    [
      name: "Deploy to Fly.io",
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
