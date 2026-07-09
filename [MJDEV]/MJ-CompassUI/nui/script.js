
window.addEventListener('message', function (event) {
    if (event.data.action === "showCompass") {
        const compass = document.getElementById("compass");
        const arrow = document.getElementById("arrow");
        const distance = document.getElementById("distance");

        compass.style.display = "flex";

        // หมุนลูกศรให้ชี้ไปทาง waypoint
        if (event.data.heading !== undefined && event.data.heading !== null) {
            arrow.style.transform = `rotate(${event.data.heading}deg)`;
        }

        distance.innerText = `${event.data.distance} m`;

    } else if (event.data.action === "hideCompass") {
        document.getElementById("compass").style.display = "none";
    }
});

