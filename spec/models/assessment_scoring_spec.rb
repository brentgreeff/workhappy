require 'rails_helper'

RSpec.describe AssessmentScoring do
  def score(responses)
    described_class.score(responses)
  end

  it 'averages the mapped points over all five questions' do
    expect(score('posture' => 4, 'screen' => 3, 'chair' => 5, 'breaks' => 2, 'lighting' => 4)).to eq 65
  end

  it 'counts an answer stored as a string of digits' do
    expect(score('posture' => '4', 'screen' => '3', 'chair' => '5', 'breaks' => '2', 'lighting' => '4')).to eq 65
  end

  it 'ignores nulls, missing keys, out-of-range and non-numeric answers and free text' do
    responses = { 'posture' => nil, 'screen' => 6, 'chair' => 'n/a', 'breaks' => 4, 'lighting' => 4,
      'comments' => 'Call me on 07700 900123' }

    # Two mappable answers only, so no score rather than a number built on junk.
    expect(score(responses)).to be_nil
    expect(score(responses.merge('posture' => 2))).to eq 58
  end

  it 'needs at least three mappable answers' do
    expect(score('posture' => 5, 'screen' => 5)).to be_nil
    expect(score('posture' => 5, 'screen' => 5, 'chair' => 5)).to eq 100
  end

  it 'gives nothing for no object at all' do
    expect(score(nil)).to be_nil
    expect(score({})).to be_nil
    expect(score([4, 4, 4])).to be_nil
    expect(score('4')).to be_nil
  end

  it 'rounds to a whole number' do
    expect(score('posture' => 1, 'screen' => 2, 'chair' => 2)).to eq 17
  end

  describe '.reason' do
    def reason(responses)
      described_class.reason(responses)
    end

    it 'is nil when there is a score' do
      expect(reason('posture' => 5, 'screen' => 5, 'chair' => 5)).to be_nil
    end

    it 'says no answers when nothing was stored or no question was answered' do
      expect(reason(nil)).to eq :no_answers
      expect(reason({})).to eq :no_answers
      expect(reason([4, 4, 4])).to eq :no_answers
      expect(reason('comments' => 'Chair is too low')).to eq :no_answers
    end

    it 'says invalid answers when questions were answered but nothing maps' do
      expect(reason('posture' => nil, 'screen' => 'n/a', 'chair' => 6)).to eq :invalid_answers
    end

    it 'says insufficient answers when some map but fewer than three' do
      expect(reason('posture' => 4, 'screen' => '3', 'chair' => nil)).to eq :insufficient_answers
    end
  end
end
