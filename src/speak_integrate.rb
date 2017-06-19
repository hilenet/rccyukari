require_relative 'speak_task.rb'

# Integrate SpeakTask I/O
# No validation
class SpeakIntegrate
  @@tasks = []

  # Create SpeakTask and return it
  # Return nil if create failed
  def publishTask text, char='ykr', ip
    speaktask = SpeakTask.new text, char, ip

    @@tasks << speaktask if speaktask!= nil

    removeTask @@tasks.shift if @@tasks.length>5

    return speaktask
  end

  # Wait or kill all speaktask
  # Return processed task num
  def clearTasks
    @@tasks.each do |task|
      task.kill
    end

    num = @@tasks.length
    @@tasks.clear

    return num
  end

  # Check each tasks that finished
  def checkTask
    @@tasks.each do |task|
      @@tasks.delete task unless task.isAlive
    end
  end
end
