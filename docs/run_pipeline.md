# run_pipeline.md

All of the steps below must be run from the repositories root directory.

1. Upload config files to config directory:
    * `config.yaml`
    * `ex_samples.csv`
    * `ex_lanes.csv`
    * `ex_adapters.csv`
    * `ex_technical_controls.csv`
    * `ms_samples.csv`
    * `download_list.csv`

2. Create tmux session
```
tmux new -s codec-session
```
3. Run docker container
```
sudo docker run -it --name codec-container -v "$PWD":/work -w /work codec-image
```
4. Run pipeline
```
bash bin/run_all.sh
```
5. Shutdown instance
