:- module(mnn3_workflow_library, [workflow/2, workflow_variant/2]).

workflow(artifact_project,
         [requirements, architecture, implementation, tests, documentation,
          verification]).

workflow_variant('MNN3-0', [artifact_generation]).
workflow_variant('MNN3-A', [artifact_generation, goal_decomposition]).
workflow_variant('MNN3-B', [artifact_generation, goal_decomposition, task_graph]).
workflow_variant('MNN3-C', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter]).
workflow_variant('MNN3-D', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter, mnn2_adapter]).
workflow_variant('MNN3-E', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter, mnn2_adapter, reviewer]).
workflow_variant('MNN3-F', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter, mnn2_adapter, reviewer, test_generation]).
workflow_variant('MNN3-G', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter, mnn2_adapter, reviewer, test_generation,
                            revision]).
workflow_variant('MNN3-H', [artifact_generation, goal_decomposition, task_graph,
                            mnn1_adapter, mnn2_adapter, reviewer, test_generation,
                            revision, workflow_optimisation]).
workflow_variant('MNN3', [complete_artifact_agent]).
