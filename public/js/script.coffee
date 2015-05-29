# identify peaks
getPeaksAtThreshold = (data, threshold) ->
    length = data.length
    peaksArray = []

    i = 0
    while i < length
        if data[i] > threshold
            peaksArray.push i
            # skip ~0.25s past this peak
            i += 10000
        i++

    peaksArray

# return a histogram of peak intervals
countIntervalsBetweenNearbyPeaks = (peaks) ->
    intervalCounts = []
    peaks.forEach (peak, index) ->
        i = 0
        while i < 10
            interval = peaks[index + i] - peak
            foundInterval = intervalCounts.some((intervalCount) ->
                if intervalCount.interval == interval
                    return intervalCount.count++
                return
            )
            if !foundInterval
                intervalCounts.push
                    interval: interval
                    count: 1
            i++
        return
    intervalCounts

# return a histogram of tempo candidates
groupNeighborsByTempo = (intervalCounts, sampleRate) ->
    tempoCounts = []
    intervalCounts.forEach (intervalCount, i) ->
        if intervalCount.interval isnt 0
            # interval -> tempo
            tempo = 60 / (intervalCount.interval / sampleRate)

            # adjust to fit within [90,180] bpm range
            while tempo < 90
                tempo *= 2
            while tempo > 180
                tempo /= 2

            tempo = Math.round tempo

            foundTempo = tempoCounts.some((tempoCount) ->
                if tempoCount.tempo is tempo
                    return tempoCount.count += intervalCount.count
                return
            )

            if !foundTempo
                tempoCounts.push
                    tempo: tempo
                    count: intervalCount.count
        return

    tempoCounts

window.onload = ->
    audioTag     = document.getElementById("audio")
    preview      = document.getElementById("preview").innerHTML
    audioTag.src = preview

    isPlaying = no
    playButton = document.getElementById("play")
    playButton.addEventListener 'click', ->
        if isPlaying
            isPlaying = no
            audioTag.pause()
        else
            isPlaying = yes
            audioTag.play()

    context = new AudioContext()
    request = new XMLHttpRequest()

    request.open 'GET', preview, true
    request.responseType = 'arraybuffer'
    request.onload = ->
        context.decodeAudioData request.response, ((buffer) ->
            # create offline context
            offlineContext = new OfflineAudioContext(1, buffer.length, buffer.sampleRate)

            # create buffer source
            source = offlineContext.createBufferSource()
            source.buffer = buffer

            # create filter
            filter = offlineContext.createBiquadFilter()
            filter.type = 'lowpass'

            # pipe song -> filter -> offline context
            source.connect filter
            filter.connect offlineContext.destination

            # song starts @ 0
            source.start 0

            # render the song
            offlineContext.startRendering()

            # act on the result
            offlineContext.oncomplete = (s) ->
                filteredBuffer = s.renderedBuffer

                initThreshold = 0.9
                threshold     = initThreshold
                minThreshold  = 0.3
                minPeaks      = 30

                loop
                    peaks = getPeaksAtThreshold(s.renderedBuffer.getChannelData(0), threshold)
                    threshold -= 0.05
                    unless peaks.length < minPeaks and threshold >= minThreshold
                        break

                intervals = countIntervalsBetweenNearbyPeaks peaks
                groups    = groupNeighborsByTempo(intervals, filteredBuffer.sampleRate)

                top = groups.sort((i1, i2) ->
                    i2.count - i1.count
                ).splice(0, 5)

                document.getElementById('bpm').innerHTML = top[0].tempo
                return

            return
        ), ->
        return

    request.send()
    return

