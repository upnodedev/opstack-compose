# Use an official Node.js runtime as a parent image
FROM node:16

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY package*.json ./
COPY index.js ./

# Install dependencies
RUN npm install

# Make port 3001 available to the world outside this container
EXPOSE 3001

# Run the app when the container launches
CMD ["node", "index.js"]
