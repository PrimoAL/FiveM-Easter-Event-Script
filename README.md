# 🥚 FiveM Easter Egg Hunt

An interactive Easter egg hunt script for FiveM servers using the ESX framework. This resource adds a fun, seasonal event to your server where players can find eggs scattered throughout the map, solve poem puzzles, and earn rewards.

![Easter Egg Hunt](https://cdn.astro-life.com/github/easter-script.png)

## ✨ Features

- 🥚 Beautifully designed 3D Easter eggs scattered across the map
- 🧩 Interactive poem puzzles for players to solve
- 💰 Reward system including money, items, and coins
- 📊 Admin statistics panel to monitor player progress
- 🗺️ Admin-only Easter egg location blips
- 🎮 User-friendly UI with animations and visual effects
- 🔄 Full database integration for persistent progress tracking

## 📋 Requirements

- [es_extended](https://github.com/esx-framework/esx-legacy) (ESX Framework)
- [MySQL-Async](https://github.com/brouznouf/fivem-mysql-async)

## 💾 Installation

1. Download or clone this repository
2. Place the `astro_oster` folder in your FiveM server's `resources` directory
3. Add `ensure astro_oster` to your server.cfg
4. Restart your server

The script will automatically create the necessary database tables on the first startup.

## 🖥️ Usage

### Player Commands

- `/osterfortschritt` - Check your current Easter egg collection progress

### Admin Commands

- `/addeasteregg` - Place a new Easter egg at your current position
- `/toggleeasterblips` - Toggle visibility of Easter egg blips on the map (admin-only)
- `/easterstats` - Open the admin statistics panel showing player progress

## 🎮 How It Works

1. Admins place Easter eggs throughout the map using `/addeasteregg`
2. Players explore the world looking for the decorated Easter eggs
3. When a player finds an egg, they can interact with it by pressing E
4. The player has to complete a rhyming poem by entering the correct word
5. Upon successful completion, players receive rewards and the egg is marked as collected
6. Players can track their progress with the `/osterfortschritt` command
7. Special rewards are given to players who find all eggs

## 🎨 Customization

### Poem Configuration

The script comes with 15 pre-configured German rhyming poems. You can modify these or add new ones by editing the poem entries in the server.sql file or directly in the database.

### Rewards Configuration

Rewards can be customized in the `server.lua` file:

```lua
local rewardType = math.random(1, 5)

-- Edit these values to adjust reward types and amounts
if rewardType == 1 then
    local moneyAmount = math.random(50, 150)
    -- Money reward
elseif rewardType == 2 then
    -- Item reward
elseif rewardType == 3 then
    -- Coin reward
-- etc.
```

### Visual Customization

The UI design can be customized by editing the `style.css` file in the `html` folder.

## 📊 Database Schema

The script creates three tables in your database:

1. `easter_eggs` - Stores information about the eggs and their locations
2. `easter_poems` - Contains the poem puzzles
3. `easter_collected` - Tracks which players have found which eggs

## 🛠️ Technical Details

### Client-Side

- Handles egg marker rendering
- Manages player interactions
- Controls UI display and animations
- Tracks local player progress

### Server-Side

- Manages database operations
- Controls player rewards
- Synchronizes egg data between all players
- Validates poem solutions
- Tracks player statistics

## 🔄 Synchronization

The script automatically synchronizes egg data:
- When players join the server
- Every 60 seconds to ensure all clients have up-to-date information
- When an admin places a new egg
- When a player collects an egg

## 👩‍💻 Development

### File Structure

- `client.lua` - Client-side functionality
- `server.lua` - Server-side functionality and database operations
- `html/index.html` - UI structure
- `html/script.js` - UI functionality
- `html/style.css` - UI styling

### Adding New Features

The codebase is well-documented and modular, making it easy to extend with new features such as:
- Additional reward types
- New egg designs
- Alternative puzzle types
- Seasonal themes

## 📝 License

This resource is released under the [MIT License](LICENSE).

## 🙏 Credits

Developed by AstroRP
FiveM ESX Framework

---

⭐ If you like this resource, please leave a star on GitHub!
