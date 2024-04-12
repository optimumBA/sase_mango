defmodule GithubWorkflows do
  @moduledoc """
  Run `mix github_workflows.generate` after updating this module.
  See https://hexdocs.pm/github_workflows_generator.
  """

  @app_name "sase-mango"
  @environment_name "pr-${{ github.event.number }}"
  @preview_app_name "#{@app_name}-#{@environment_name}"
  @preview_app_host "#{@preview_app_name}.fly.dev"
  @repo_name "sase_mango"

  def get do
    %{
      "main.yml" => main_workflow(),
      "pr.yml" => pr_workflow(),
      "pr_closure.yml" => pr_closure_workflow()
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
          deploy_staging_app: deploy_staging_app_job()
        ]
      ]
    ]
  end

  defp pr_workflow do
    [
      [
        name: "PR",
        on: [
          pull_request: [
            branches: ["main"],
            types: ["opened", "reopened", "synchronize"]
          ]
        ],
        jobs: [
          deploy_preview_app: deploy_preview_app_job()
        ]
      ]
    ]
  end

  defp pr_closure_workflow do
    [
      [
        name: "PR closure",
        on: [
          pull_request: [
            branches: ["main"],
            types: ["closed"]
          ]
        ],
        jobs: [
          delete_preview_app: delete_preview_app_job()
        ]
      ]
    ]
  end

  defp delete_preview_app_job do
    [
      name: "Delete preview app",
      "runs-on": "ubuntu-latest",
      concurrency: [group: "pr-${{ github.event.number }}"],
      steps: [
        checkout_step(),
        [
          name: "Delete preview app",
          uses: "optimumBA/fly-preview-apps@main",
          env: [
            FLY_API_TOKEN: "${{ secrets.FLY_API_TOKEN }}",
            REPO_NAME: @repo_name
          ],
          with: [
            name: @preview_app_name
          ]
        ],
        [
          name: "Generate token",
          uses: "navikt/github-app-token-generator@v1.1.1",
          id: "generate_token",
          with: [
            "app-id": "${{ secrets.GH_APP_ID }}",
            "private-key": "${{ secrets.GH_APP_PRIVATE_KEY }}"
          ]
        ],
        [
          name: "Delete GitHub environment",
          uses: "strumwolf/delete-deployment-environment@v2.2.3",
          with: [
            token: "${{ steps.generate_token.outputs.token  }}",
            environment: @environment_name,
            ref: "${{ github.head_ref }}"
          ]
        ]
      ]
    ]
  end

  defp deploy_job(env, opts) do
    [
      name: "Deploy #{env} app",
      "runs-on": "ubuntu-latest"
    ] ++ opts
  end

  defp deploy_preview_app_job do
    deploy_job("preview",
      permissions: "write-all",
      concurrency: [group: @environment_name],
      environment: preview_app_environment(),
      steps: [
        checkout_step(),
        delete_previous_deployments_step(),
        [
          name: "Deploy preview app",
          uses: "optimumBA/fly-preview-apps@main",
          env: fly_env(),
          with: [
            name: @preview_app_name,
            secrets:
              "ADMIN_PASSWORD=${{ secrets.ADMIN_PASSWORD }} ADMIN_USERNAME=${{ secrets.ADMIN_USERNAME }} PHX_HOST=${{ env.PHX_HOST }} SECRET_KEY_BASE=${{ secrets.SECRET_KEY_BASE }}",
            vm_memory: 1024
          ]
        ]
      ]
    )
  end

  defp deploy_staging_app_job do
    deploy_job("staging",
      steps: [
        checkout_step(),
        [
          uses: "superfly/flyctl-actions/setup-flyctl@master"
        ],
        [
          run: "flyctl deploy --remote-only",
          env: [
            FLY_API_TOKEN: "${{ secrets.FLY_API_TOKEN }}"
          ]
        ]
      ]
    )
  end

  defp checkout_step do
    [
      name: "Checkout",
      uses: "actions/checkout@v4"
    ]
  end

  defp delete_previous_deployments_step do
    [
      name: "Delete previous deployments",
      uses: "strumwolf/delete-deployment-environment@v2.2.3",
      with: [
        token: "${{ secrets.GITHUB_TOKEN }}",
        environment: @environment_name,
        ref: "${{ github.head_ref }}",
        onlyRemoveDeployments: true
      ]
    ]
  end

  defp fly_env do
    [
      FLY_API_TOKEN: "${{ secrets.FLY_API_TOKEN }}",
      FLY_ORG: "optimum-bh",
      FLY_REGION: "fra",
      PHX_HOST: "#{@preview_app_name}.fly.dev",
      REPO_NAME: @repo_name
    ]
  end

  defp preview_app_environment do
    [
      name: @environment_name,
      url: "https://#{@preview_app_host}"
    ]
  end
end
