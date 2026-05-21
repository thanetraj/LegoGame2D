# LEGO 2D Game

**LEGO 2D Game** is a 2D top-down survival horror game developed using the **Godot Engine 4.6** and GDScript. This project was built as a Major Project for the final semester of the Diploma in Engineering in Computer Science & Engineering.

The game is inspired by the survival horror genre, placing the player inside a dark, procedurally generated maze. The player must collect glowing items to meet a quota target while balancing three critical resources: Health, Fear, and Battery. 

## 🌟 Key Features

- **Progressive Difficulty:** 10 distinct levels with expanding maze sizes (from 4x4 up to 13x13 grids) and increasing quota requirements.
- **Resource Management:** Balance Health, Battery (for the flashlight), and Fear. High fear causes continuous health drain.
- **Dynamic Enemy AI (FSM):** 
  - *Shadow Enemies* (Melee): Patrol the maze, chase the player upon detection, and deal heavy damage.
  - *Shooter Enemies* (Ranged - Level 6+): Patrol and fire 3-round bursts of laser projectiles.
- **Ranged Combat System:** Starting from Level 6, the player unlocks a laser weapon to fight back against the enemies.
- **Procedural Audio System:** All game audio (heartbeats, ambient drones, laser blasts, monster growls) is generated procedurally using Godot's `AudioStreamGenerator`—no external sound files were used!
- **Line-of-Sight Fog of War:** Enemies and items are hidden in the shadows and only revealed when the player has a direct line of sight.
- **Dynamic Respawn System:** Defeated enemies respawn after a short delay, keeping the maze constantly dangerous.

## 🎮 Controls

| Action | Key / Input |
|---|---|
| **Move Up** | `W` |
| **Move Down** | `S` |
| **Move Left** | `A` |
| **Move Right** | `D` |
| **Sprint** | `Shift` (Hold) |
| **Toggle Flashlight** | `F` |
| **Interact / Collect** | `E` |
| **Fire Laser** (Level 6+) | `V` or `Right-Click` |

## 🛠️ Built With

- **[Godot Engine 4.6.x](https://godotengine.org/)** - The core game engine
- **GDScript** - Programming language used for all logic
- **Git & GitHub** - Version control

## ⚙️ How to Run Locally

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/thanetraj/LegoGame2D.git
   ```
2. Download and open **Godot Engine 4.6+**.
3. Click on **Import**, navigate to the cloned folder, and select the `project.godot` file.
4. Once the project opens in the editor, click the **Play** button (or press `F5`) to run the game!

## 🎓 About

Created by **Thanet Raj Dewangan** as a final semester Major Project for the Diploma in Engineering (Computer Science & Engineering) program. 
