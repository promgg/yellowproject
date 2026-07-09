
addEventListener("message", function(event) {
    if(event.data.meta == "me") {
		document.getElementById("me").innerHTML = event.data.html;
	} else if (event.data.meta == "do") {
		document.getElementById("do").innerHTML = event.data.html;
	} else if (event.data.meta == "Text3D") {
		document.getElementById("Text").innerHTML = event.data.html;
	}
});

// window.addEventListener('message', function(event) {
//     const data = event.data;

//     if (data.type === "me") {
//         $('#me').html(`<p>${data.text}</p>`).fadeIn(100).delay(3200).fadeOut(300);
//     } else if (data.type === "do") {
//         $('#do').html(`<p>${data.text}</p>`).fadeIn(100).delay(3200).fadeOut(300);
//     } else if (data.type === "text") {
//         $('#Text').html(`<p>${data.text}</p>`).fadeIn(100).delay(3200).fadeOut(300);
//     }
// });
