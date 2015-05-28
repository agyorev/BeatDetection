window.onload = ->
    audioTag = document.getElementById("audio")
    audioTag.src = document.getElementById("preview").innerHTML

    isPlaying = no
    playButton = document.getElementById("play")
    playButton.addEventListener 'click', ->
        if isPlaying
            isPlaying = no
            audioTag.pause()
        else
            isPlaying = yes
            audioTag.play()
