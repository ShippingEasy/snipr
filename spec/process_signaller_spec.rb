require 'spec_helper'
require 'ostruct'

module Snipr
  describe ProcessSignaller do
    let(:signal) {Signal.list["USR1"]}
    let(:ps_output) {File.read("spec/ps_output.txt").split("\n")}
    let(:checkins) {OpenStruct.new}
    subject do
      ProcessSignaller.new do |signaller|
        signaller.include /resque/i
        signaller.signal  "USR1"

        signaller.on_no_processes do
          checkins.on_no_processes = true
        end

        signaller.before_signal do |signal, process|
          checkins.before_signal = "#{signal} > #{process.pid}"
        end

        signaller.after_signal do |signal, process|
          checkins.after_signal = "#{signal} > #{process.pid}"
        end

        signaller.on_error do |exc, signal, process|
          msg = "#{exc}"
          if signal && process
            msg += " #{signal} > #{process.pid}"
          end
          checkins.on_error = msg
        end
      end
    end

    describe "#signal" do
      it "should raise an error if the signal is not defined by the system" do
        expect{subject.signal("AJDKASDJKLASD")}.to raise_error
      end

      it "should assign the numeric value of the signal as defined by the system" do
        expect(subject.signal("USR1")).to eq(Signal.list["USR1"])
      end
    end

    describe "#signal" do
      context "when there is a general failure" do
        let(:locator) {subject.instance_variable_get(:@locator)}

        it "should invoke the on_error callback" do
          expect(locator).to receive(:locate).and_raise('Ouch!')
          subject.send_signals
          expect(checkins.on_error).to eq("Ouch!")
        end
      end

      context "when no processes found" do
        before {subject.exclude /resque/i}
        it "should invoke the on_no_processes callback" do
          subject.send_signals
          expect(checkins.on_no_processes).to be_truthy
        end
      end

      context "when process is found" do
        before do
          expect(Snipr).to receive(:exec_cmd).and_return(ps_output).at_least(:once)
          subject.cpu_greater_than(90)
        end

        context "targetting the process itself" do
          it "should send the appropriate signal to the process and call callbacks" do
            expect(Process).to receive(:kill).with(signal, 6337)
            subject.send_signals
            expect(checkins.before_signal).to eq("#{signal} > 6337")
            expect(checkins.after_signal).to eq("#{signal} > 6337")
          end
        end
        
        context "targetting the parent process" do
          it "should send the appropriate signal to the parent process and call callbacks" do
            subject.target_parent true
            expect(Process).to receive(:kill).with(signal, 4347)
            subject.send_signals
            expect(checkins.before_signal).to eq("#{signal} > 6337")
            expect(checkins.after_signal).to eq("#{signal} > 6337")
          end
        end

        context "when encountering an error signalling a process" do
          it "should call the on_error callback" do
            expect(Process).to receive(:kill).with(signal, 6337).and_raise('Ouch!')
            subject.send_signals
            expect(checkins.on_error).to eq("Ouch! #{signal} > 6337")
          end
        end
      end
    end
  end
end
