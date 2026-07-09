$(function(){
    $('.Content').append(`<img src="./logo.png" />`);
    window.addEventListener('message', (event) => {
        var item = event.data;

        if (item.type === 'ui') {
            if (item.display) {
                $('.Content').fadeIn(300);    
                
            } else {
                $('.Content').fadeOut(300);   

            }

        } else if (item.type == 'pos') {
            if (item.position == 'esquerda') {
                changePosition('justify-content', 'flex-start')
                
            } else if (item.position == 'direita') {
                changePosition('justify-content', 'flex-end')                
                
            } else if (item.position == 'centro') {
                changePosition('justify-content', 'center')                

            } else if (item.position == 'off') {
                $('.Content').fadeOut(300);   

            } else if (item.position == 'on') {
                $('.Content').fadeIn(300);  

            }
        }

    });

});

function changePosition(key, value) {
    $('.Content').fadeOut(200);
    
    setTimeout(() => {
        $('.Content').css(key, value)
        
    }, 200);

    $('.Content').fadeIn(200); 
}