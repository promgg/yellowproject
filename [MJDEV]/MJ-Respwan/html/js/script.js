$(function () {
    function display(show) {
        if (show) {
            $('body').css('display', 'flex').fadeIn();
        } else {
            $('body').fadeOut();
        }
    }

    function setButtonState(type, active) {
        const bgColor = active ? '#ff0000' : 'gray';
        const textColor = bgColor;

        if (type === 'y') {
            $(".y").css("background", bgColor);
            $(".btn .b p").css("color", textColor);
        } else if (type === 'x') {
            $(".x").css("background", bgColor);
            $(".btn .a p").css("color", textColor);
        }
    }

    window.addEventListener('message', function (event) {
        const item = event.data;

        switch (item.type) {
            case 'ui':
                display(item.status);
                if (item.status) $('#PlayerId').html(item.id);
                break;

            case 'respawn':
                $('#text-re').html(item.text);
                if (item.text === '0:0') {
                    setButtonState('x', true);
                }
                break;

            case 'addclass':
                setButtonState('x', !item.status); // true = gray, false = red
                break;

            case 'addclass2':
                setButtonState('y', !item.status); // true = gray, false = red
                break;
        }
    });
});
