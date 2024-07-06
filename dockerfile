# Use the Anaconda3 base image
FROM continuumio/anaconda3

# Set timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Expose port
EXPOSE 7363

# Install dependenceis
RUN apt-get update && \
    apt-get install -y -qq aria2 ffmpeg && apt clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Create the conda environment and activate it
RUN conda create -n wav2lip python=3.10 && \
    echo "source activate wav2lip" > ~/.bashrc

# Activate the environment
SHELL ["conda", "run", "-n", "wav2lip", "/bin/bash", "-c"]

# Clone the Wav2Lip-WebUI repository
COPY . .

# Install PyTorch and other dependencies
RUN conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y && \
    pip install -r requirements.txt && \
    conda clean -a

# download models
RUN aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/mozi1924/wav2lip/resolve/main/s3fd-619a316812.pth -d face_detection/detection/sfd -o s3fd-619a316812.pth && \
    aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/mozi1924/wav2lip/resolve/main/wav2lip.pth -d checkpoints/ -o wav2lip.pth && \
    aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/mozi1924/wav2lip/resolve/main/wav2lip_gan.pth -d checkpoints/ -o wav2lip_gan.pth

# Set the entry point to the bash shell
# ENTRYPOINT ["/bin/bash", "-c", "source activate wav2lip && exec bash"]

VOLUME [ "/app/results" ]

# Run the application
CMD ["/opt/conda/envs/wav2lip/bin/python", "ui.py"]
