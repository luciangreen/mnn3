:- module(mnn3_workflow_library, [workflow/2, workflow_variant/2]).

workflow(artifact_project,
         [security_kernel, requirements, architecture, implementation, tests,
          documentation, verification]).

workflow_variant('MNN3-0', [security_kernel, artifact_generation]).
workflow_variant('MNN3-A', [security_kernel, artifact_generation, goal_decomposition]).
workflow_variant('MNN3-B', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph]).
workflow_variant('MNN3-C', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter]).
workflow_variant('MNN3-D', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter, mnn2_adapter]).
workflow_variant('MNN3-E', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter, mnn2_adapter, reviewer]).
workflow_variant('MNN3-F', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter, mnn2_adapter, reviewer,
                            test_generation]).
workflow_variant('MNN3-G', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter, mnn2_adapter, reviewer,
                            test_generation, revision]).
workflow_variant('MNN3-H', [security_kernel, artifact_generation, goal_decomposition,
                            task_graph, mnn1_adapter, mnn2_adapter, reviewer,
                            test_generation, revision, workflow_optimisation]).
workflow_variant('MNN3', [security_kernel, complete_artifact_agent]).
