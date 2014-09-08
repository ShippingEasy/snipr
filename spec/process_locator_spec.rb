require 'spec_helper'

module Snipr
  describe ProcessLocator do
    describe "#parse_seconds" do
      let(:result) {subject.send(:parse_seconds, etime)}

      describe "with a time spanning days" do
        let(:etime) {"1-02:03:04"}
        it "should calculate the correct number of seconds" do
          expect(result).to eq(93784)
        end
      end

      describe "with a time spanning hours" do
        let(:etime) {"2:03:04"}
        it "should calculate the correct number of seconds" do
          expect(result).to eq(7384)
        end
      end

      describe "with a time spanning minutes" do
        let(:etime) {"03:04"}
        it "should calculate the correct number of seconds" do
          expect(result).to eq(184)
        end
      end

      describe "with a time spanning seconds" do
        let(:etime) {"04"}
        it "should calculate the correct number of seconds" do
          expect(result).to eq(4)
        end
      end
    end

    describe "#locate" do
      let(:ps_output) {File.read("spec/ps_output.txt").split("\n")}
      before do
        expect(Snipr).to receive(:exec_cmd).and_return(ps_output).at_least(:once)
      end

      it "should return an array of KernelProcess objects" do
        process = subject.locate.select{|process| process.pid == 3552}.first
        expect(process.pid).to eq(3552)
        expect(process.ppid).to eq(4354)
        expect(process.memory).to eq(1297860)
        expect(process.cpu).to eq(8.7)
        expect(process.etime).to eq("1-07:12:08")
        expect(process.seconds_alive).to eq(112328)
        expect(process.command).to eq("resque-1.24.1: Processing foo since 1410077129 [FooJob]")
      end

      describe "when no processes match filters" do
        it "should return an empty array" do
          subject.include /thereisnoinputwiththisstring/
          expect(subject.locate).to be_empty
        end
      end

      describe "when a single include is specified" do
        it "should return all processes that match the include pattern" do
          subject.include /Processing/
          expect(subject.locate.size).to eq(20)
        end
      end

      describe "when multiple includes are specified" do
        it "should return all processses that match all include patterns" do
          subject.include /Processing/
          subject.include /Delayed Items/
          expect(subject.locate.size).to eq(1)
        end
      end

      describe "when a single exclude is specified" do
        it "should return all processes not matching the exclude pattern" do
          subject.exclude /grep/
          expect(subject.locate.size).to eq(52)
        end
      end

      describe "when multiple excludes are specified" do
        it "should return all processes that don't match all exclude patterns" do
          subject.exclude /grep/
          subject.exclude /scheduler/
          expect(subject.locate.size).to eq(51)
        end
      end

      describe "when filtering processes by memory greater than" do
        it "should return only processes using memory greater than the specified amount" do
          subject.memory_greater_than(1000000000)
          expect(subject.locate.size).to eq(1)
          expect(subject.locate.first.pid).to eq(32178)
        end
      end

      describe "when filtering processes by cpu greater than" do
        it "should return only processes using cpu greater than the specified amount" do
          subject.cpu_greater_than(90.0)
          expect(subject.locate.size).to eq(1)
          expect(subject.locate.first.pid).to eq(6337)
        end
      end

      describe "when filtering processes by alive longer than" do
        it "should return only processes that have been alive longer than the specified amount" do
          subject.alive_longer_than(31449600)
          expect(subject.locate.size).to eq(1)
          expect(subject.locate.first.pid).to eq(28309)
        end
      end

      describe "when filtering by a custom filter" do
        it "should return only processes that match the filter" do
          subject.filter { |process| process.pid % 2 == 0 }
          expect(subject.locate.size).to eq(24)
        end
      end
    end
  end
end
