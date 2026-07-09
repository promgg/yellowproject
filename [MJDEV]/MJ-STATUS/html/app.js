

// PLAYER HUD
const playerHud = {
    data() {
        return {
            health: 0,
            stamina: 0,
            armor: 0,
            hunger: 0,
            thirst: 0,
            cleanliness: 0,
            stress: 0,
            voice: 0,
            temp: 0,
            horsehealth: 0,
            horsestamina: 0,
            horseclean: 0,
            show: false,
            talking: false,
            showVoice: true,
            showHealth: true,
            showStamina: true,
            showArmor: true,
            showHunger: true,
            showThirst: true,
            showCleanliness: true,
            showStress: true,
            showHorseStamina: false,
            showHorseHealth: false,
            showHorseClean: false,
            showTemp: true,
            showHorseStaminaColor: "#a16600",
            showHorseHealthColor: "#a16600",
            showHorseCleanColor: "#a16600",
            talkingColor: "#FFFFFF",
        }
    },
    destroyed() {
        window.removeEventListener('message', this.listener);
    },
    mounted() {
        this.listener = window.addEventListener('message', (event) => {
            if (event.data.action === 'hudtick') {
                this.hudTick(event.data);
            }
        });
    },
    methods: {
        hudTick(data) {
            this.show = data.show;
            this.health = data.health;
            this.stamina = parseInt(data.stamina);
            this.armor = data.armor;
            this.hunger = data.hunger;
            this.thirst = data.thirst;
            this.cleanliness = data.cleanliness;
            this.stress = data.stress;
            this.voice = data.voice;
            this.temp = data.temp;
            this.talking = data.talking;
            this.showHorseStamina = data.onHorse;
            this.showHorseHealth = data.onHorse;
            this.showHorseClean = data.onHorse;
            if (data.onHorse) {
                this.horsehealth = data.horsehealth;
                this.horsestamina = data.horsestamina;
                this.horseclean = data.horseclean;
            }
            if (data.health >= 100) {
                this.showHealth = false;
            } else {
                this.showHealth = true;
            }
            if (data.health <= 30 ) {
              this.showHealthColor = "#FF0000";
            } else {
                this.showHealthColor = "#FFF";
            }
            if (parseInt(data.stamina) >= 100) {
                this.showStamina = false;
            } else {
                this.showStamina = true;
            }
            if (parseInt(data.stamina) <= 30 ) {
              this.showStaminaColor = "#FF0000";
            } else {
                this.showStaminaColor = "#FFF";
            }
            if (data.hunger <= 30) {
                this.showHungerColor = "#FF0000";
            } else {
                this.showHungerColor = "#FFF";
            }
            if (data.thirst <= 30 ) {
                this.showThirstColor = "#FF0000";
            } else {
                this.showThirstColor = "#FFF";
            }
            if (data.cleanliness <= 30 ) {
                this.showCleanlinessColor = "#FF0000";
            } else {
                this.showCleanlinessColor = "#FFF";
            }
            if (data.armor <= 0) {
                this.showArmor = false;
            } else {
                this.showArmor = true;
            }
            if (data.hunger >= 100) {
                this.showHunger = false;
            } else {
                this.showHunger = true;
            }
            if (data.thirst >= 100) {
                this.showThirst = false;
            } else {
                this.showThirst = true;
            }
            if (data.cleanliness >= 100) {
                this.showCleanliness = false;
            } else {
                this.showCleanliness = true;
            }
            if (data.stress <= 0) {
                this.showStress = false;
            } else {
                this.showStress = true;
            }
            // if (data.talking) {
            //     this.showVoice = true;
            // } else {
            //     this.showVoice = false;
            // }
            if (data.talking > 0) {
                this.talkingColor = "#00FF00"; // สีเขียว
                this.talkingIcon = "fas fa-microphone"; // ไอคอนไมโครโฟน
            } else {
                this.talkingColor = "#FF0000"; // สีแดง
                this.talkingIcon = "fas fa-microphone-slash"; // ไอคอนไมโครโฟนกากบาท
            }                      
            if (data.temp >= 0) {
                this.showTemp = false;
            } else {
                this.showTemp = true;
            }
            if (data.temp <= 30) {
                this.showTempColor = "#FDD021";
            } else {
                this.showTempColor = "#CFBCAE";
            }
        }
    }
}
const app = Vue.createApp(playerHud);
app.use(Quasar)
app.mount('#ui-container');
