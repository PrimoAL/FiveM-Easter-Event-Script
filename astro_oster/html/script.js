let currentEggId = null;
let animationsCreated = false;

$(document).ready(function() {
    createFallingEggs();
    createGrass();
    
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === "openEgg") {
            $('#falling-eggs').show();
            $('#grass').show();
            
            currentEggId = data.eggId;
            $('#poem-start').text(data.poemStart);
            $('#poem-answer').val('');
            $('#egg-container').css('display', 'flex');
            $('#poem-answer').focus();
            //playOpenSound();
        } else if (data.type === "closeEgg") {
            closeEggUI();
        }
    });
    
    $('#submit-btn').click(function() {
        const answer = $('#poem-answer').val().trim();
        if (answer === '') {
            shakeInput();
            return;
        }
        
        $.post('https://astro_oster/submitPoem', JSON.stringify({
            answer: answer,
            eggId: currentEggId
        }));
    });
    
    $('#close-btn').click(function() {
        $.post('https://astro_oster/closeUI', JSON.stringify({}));
    });
    
    $('#poem-answer').keypress(function(e) {
        if (e.which === 13) { // Enter Key
            $('#submit-btn').click();
        }
    });
});

function closeEggUI() {
    $('#egg-container').css('display', 'none');
    $('#falling-eggs').hide();
    $('#grass').hide();
    currentEggId = null;
}

function shakeInput() {
    $('#poem-answer').addClass('bounce');
    setTimeout(function() {
        $('#poem-answer').removeClass('bounce');
    }, 1000);
}

function playOpenSound() {
    try {
        const audio = new Audio('sfx/open.mp3');
        audio.volume = 0.2;
        audio.play().catch(e => console.log('Sound konnte nicht abgespielt werden:', e));
    } catch (err) {
        console.log('Sound-Fehler:', err);
    }
}

function createFallingEggs() {
    const container = document.getElementById('falling-eggs');
    const eggTypes = ['fa-egg', 'fa-egg', 'fa-carrot', 'fa-egg', 'fa-egg'];
    const eggColors = ['#FFD54F', '#F8BBD0', '#81D4FA', '#AED581', '#B39DDB'];
    const numberOfEggs = 20;
    
    for (let i = 0; i < numberOfEggs; i++) {
        const egg = document.createElement('i');
        const randomType = eggTypes[Math.floor(Math.random() * eggTypes.length)];
        const randomColor = eggColors[Math.floor(Math.random() * eggColors.length)];
        const randomLeft = Math.random() * 100; 
        const randomSize = Math.random() * 20 + 10; 
        const randomDuration = Math.random() * 10 + 10; 
        const randomDelay = Math.random() * 10; 
        
        egg.classList.add('fa-solid', randomType, 'falling-egg');
        egg.style.left = `${randomLeft}%`;
        egg.style.fontSize = `${randomSize}px`;
        egg.style.color = randomColor;
        egg.style.animationDuration = `${randomDuration}s`;
        egg.style.animationDelay = `${randomDelay}s`;
        
        container.appendChild(egg);
    }
}

function createGrass() {
    const container = document.getElementById('grass');
    const numberOfBlades = 100;
    
    for (let i = 0; i < numberOfBlades; i++) {
        const blade = document.createElement('div');
        const randomLeft = Math.random() * 100; 
        const randomHeight = Math.random() * 30 + 30; 
        const randomWidth = Math.random() * 5 + 2; 
        const randomColor = Math.random() > 0.5 ? '#4CAF50' : '#8BC34A'; 
        
        blade.classList.add('grass-blade');
        blade.style.left = `${randomLeft}%`;
        blade.style.height = `${randomHeight}px`;
        blade.style.width = `${randomWidth}px`;
        blade.style.backgroundColor = randomColor;
        blade.style.opacity = '0.8';
        
        container.appendChild(blade);
    }
}

$(document).ready(function() {
    createFallingEggs();
    createGrass();

    window.addEventListener('message', function(event) {
        const data = event.data;

        if (data.type === "openStats") {
            openStatsUI(data.players);
        } else if (data.type === "closeStats") {
            closeStatsUI();
            }
        });

        $('#close-btn-stats').click(function() {
            $.post('https://astro_oster/closeUI', JSON.stringify({}));
            closeStatsUI();
        });
    });

    function openStatsUI(playersData) {
        $('#players-container').empty();


        playersData.forEach((player, index) => {
        const progressPercent = Math.floor((player.eggs_found / player.total_eggs) * 100);
        const jobDisplay = player.job_label || player.job;
        const jobGrade = player.grade_label ? ` - ${player.grade_label}` : '';

        const playerCard = `
            <div class="player-card card-animation" style="animation-delay: ${index * 100}ms">
                <div class="player-name">${player.firstname} ${player.lastname}</div>
                <div class="player-info">
                    <div class="info-group">
                        <div class="info-item info-identifier">
                            <div class="info-icon"><i class="fa-solid fa-id-card"></i></div>
                            <div class="info-details">
                                <div class="info-label">Identifier</div>
                                <div class="info-value">${player.identifier}</div>
                            </div>
                        </div>
                        <div class="info-item info-phone">
                            <div class="info-icon"><i class="fa-solid fa-phone"></i></div>
                            <div class="info-details">
                                <div class="info-label">Telefonnummer</div>
                                <div class="info-value">${player.phone_number || 'Keine'}</div>
                            </div>
                        </div>
                    </div>
                    <div class="info-group">
                        <div class="info-item info-coins">
                            <div class="info-icon"><i class="fa-solid fa-coins"></i></div>
                            <div class="info-details">
                                <div class="info-label">Coins</div>
                                <div class="info-value">${player.coins || '0'}</div>
                            </div>
                        </div>
                        <div class="info-item info-job">
                            <div class="info-icon"><i class="fa-solid fa-briefcase"></i></div>
                            <div class="info-details">
                                <div class="info-label">Job</div>
                                <div class="info-value">${jobDisplay}${jobGrade}</div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="eggs-progress-container">
                    <div class="eggs-progress">
                        <div class="eggs-bar" style="width: 0%"></div>
                    </div>
                    <div class="eggs-text">
                        <span>${player.eggs_found} von ${player.total_eggs} Eiern gefunden</span>
                        <span>${progressPercent}%</span>
                    </div>
                </div>
            </div>
        `;

        $('#players-container').append(playerCard);
    });


    $('#stats-container').css('display', 'flex');

    setTimeout(() => {
        playersData.forEach((player, index) => {
            const progressPercent = Math.floor((player.eggs_found / player.total_eggs) * 100);
            $(`.player-card:eq(${index}) .eggs-bar`).css('width', `${progressPercent}%`);
        });
    }, 500);
}

function closeStatsUI() {
    $('#stats-container').css('display', 'none');
}

function createFallingEggs() {
    const container = document.getElementById('falling-eggs');
    const eggTypes = ['fa-egg', 'fa-egg', 'fa-carrot', 'fa-egg', 'fa-egg'];
    const eggColors = ['#FFD54F', '#F8BBD0', '#81D4FA', '#AED581', '#B39DDB'];
    const numberOfEggs = 20;

    for (let i = 0; i < numberOfEggs; i++) {
        const egg = document.createElement('i');
        const randomType = eggTypes[Math.floor(Math.random() * eggTypes.length)];
        const randomColor = eggColors[Math.floor(Math.random() * eggColors.length)];
        const randomLeft = Math.random() * 100; 
        const randomSize = Math.random() * 20 + 10; 
        const randomDuration = Math.random() * 10 + 10; 
        const randomDelay = Math.random() * 10; 

        egg.classList.add('fa-solid', randomType, 'falling-egg');
        egg.style.left = `${randomLeft}%`;
        egg.style.fontSize = `${randomSize}px`;
        egg.style.color = randomColor;
        egg.style.animationDuration = `${randomDuration}s`;
        egg.style.animationDelay = `${randomDelay}s`;

        container.appendChild(egg);
    }
}

function createGrass() {
    const container = document.getElementById('grass');
    const numberOfBlades = 100;

    for (let i = 0; i < numberOfBlades; i++) {
        const blade = document.createElement('div');
        const randomLeft = Math.random() * 100; 
        const randomHeight = Math.random() * 30 + 30; 
        const randomWidth = Math.random() * 5 + 2; 
        const randomColor = Math.random() > 0.5 ? '#4CAF50' : '#8BC34A'; 

        blade.classList.add('grass-blade');
        blade.style.left = `${randomLeft}%`;
        blade.style.height = `${randomHeight}px`;
        blade.style.width = `${randomWidth}px`;
        blade.style.backgroundColor = randomColor;
        blade.style.opacity = '0.8';

        container.appendChild(blade);
    }
}