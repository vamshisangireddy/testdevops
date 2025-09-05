# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file to the working directory
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
# Using --no-cache-dir to reduce image size
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container
COPY app.py .

# Make port 5003 available to the world outside this container
EXPOSE 5003

# Run app.py when the container launches
# Using gunicorn for a more production-ready server
CMD ["gunicorn", "--bind", "0.0.0.0:5003", "app:app"]