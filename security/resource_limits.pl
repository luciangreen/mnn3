:- module(mnn3_resource_limits,
          [ max_artifact_characters/1,
            max_artifacts/1,
            max_project_characters/1,
            max_task_depth/1,
            max_task_retries/1
          ]).

max_artifact_characters(131072).
max_artifacts(50).
max_project_characters(1048576).
max_task_depth(64).
max_task_retries(3).
