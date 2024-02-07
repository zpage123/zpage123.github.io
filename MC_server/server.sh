#!/bin/bash

# 定义Minecraft服务器的文件夹路径
MC_SERVER_DIR="./MC_server"
# 定义Minecraft服务器的JAR文件名
SERVER_JAR="server.jar"
# 定义Minecraft服务器的screen会话名称
SCREEN_SESSION_NAME="minecraft_server"
# 定义EULA文件路径
EULA_FILE="$MC_SERVER_DIR/eula.txt"

# 启动Minecraft服务器
start_server() {
  # 检查server.jar文件是否存在，不存在则下载
  if [ ! -f "$MC_SERVER_DIR/$SERVER_JAR" ]; then
    echo "Downloading $SERVER_JAR..."
    wget https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar -O "$MC_SERVER_DIR/$SERVER_JAR"
  fi

  # 安装Java运行环境
  if ! command -v java &>/dev/null; then
    echo "Installing Java runtime environment..."
    sudo yum install -y java-17-openjdk
  fi

  # 检查是否同意EULA协议，如果没有同意则自动同意
  if [ ! -f "$EULA_FILE" ] || ! grep -q "eula=true" "$EULA_FILE"; then
    echo "eula=true" > "$EULA_FILE"
  fi

  # 询问用户是否关闭正版用户检验
  read -p "Do you want to disable online mode for authenticating users? (y/n): " disable_online_mode
  case $disable_online_mode in
    [Yy]* )
      echo "online-mode=false" >> "$MC_SERVER_DIR/server.properties"
      ;;
    [Nn]* )
      echo "online-mode=true" >> "$MC_SERVER_DIR/server.properties"
      ;;
    * )
      echo "Invalid input. Keeping default value for online mode."
      ;;
  esac

  # 启动Minecraft服务器
  screen -dmS "$SCREEN_SESSION_NAME" java -Xmx3G -Xms2G -jar "$MC_SERVER_DIR/$SERVER_JAR" nogui
}

# 关闭Minecraft服务器
stop_server() {
  if screen -list | grep -q "$SCREEN_SESSION_NAME"; then
    screen -S "$SCREEN_SESSION_NAME" -X stuff "stop^M"
  else
    echo "Minecraft server is not running."
  fi
}

# 强制关闭Minecraft服务器
hardstop_server() {
  if screen -list | grep -q "$SCREEN_SESSION_NAME"; then
    screen -S "$SCREEN_SESSION_NAME" -X quit
  else
    echo "Minecraft server is not running."
  fi
}

# 检查命令行参数
case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  hardstop)
    hardstop_server
    ;;
  *)
    echo "Usage: $0 {start|stop|hardstop}"
    exit 1
    ;;
esac

exit 0
