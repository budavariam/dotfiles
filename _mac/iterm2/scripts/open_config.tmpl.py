PROJECT_FOLDER= "~/project/"

class Iterm2Config:
    def __init__(self):
        self.tab_title = "Project1"
        self.tab_color = (137, 207, 240)

        self.top_left_path = f"{PROJECT_FOLDER}/frontend"
        self.top_left_command = "npm run dev"

        self.top_right_path = f"{PROJECT_FOLDER}/backend"
        self.top_right_command = "bash _start.sh"

        self.bottom_left_path = f"{PROJECT_FOLDER}/"
        self.bottom_left_command = "docker-compose up"

        self.bottom_right_path = None
        self.bottom_right_command = None
