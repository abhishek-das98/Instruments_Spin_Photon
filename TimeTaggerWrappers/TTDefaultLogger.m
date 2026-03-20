
function TTDefaultLogger(level, message)
    if level >= int32(SwabianInstruments.TimeTagger.LogLevel.LOGGER_WARNING)
        warning(char(message))
    end
end
