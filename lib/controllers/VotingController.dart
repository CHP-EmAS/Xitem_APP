import 'package:flutter/rendering.dart';
import 'package:xitem/api/VotingApi.dart';
import 'package:xitem/interfaces/ApiInterfaces.dart';
import 'package:xitem/models/Voting.dart';
import 'package:xitem/utils/ApiResponseMapper.dart';


class VotingController {
  VotingController(this._votingApi);

  final VotingApi _votingApi;

  late final String _relatedCalendarID;
  bool _isInitialized = false;

  final Map<int, Voting> _votingMap = <int, Voting>{};

  Future<ResponseCode> initialize(String relatedCalendarID) async {
    if(_isInitialized) {
      return ResponseCode.invalidAction;
    }

    _relatedCalendarID = relatedCalendarID;

    ResponseCode initialLoad = await loadAllVotings();

    if(initialLoad != ResponseCode.success) {
      _resetControllerState();
      return initialLoad;
    }

    _isInitialized = true;
    return ResponseCode.success;
  }

  // voting functions
  Future<ResponseCode> loadAllVotings() async {
    ApiResponse<List<Voting>> loadVoting = await _votingApi.loadAllVoting(_relatedCalendarID);
    List<Voting>? voteList = loadVoting.value;

    if (loadVoting.code != ResponseCode.success) {
      return loadVoting.code;
    } else if (voteList == null) {
      return ResponseCode.unknown;
    }

    _votingMap.clear();

    for (var voting in voteList) {
      _votingMap[voting.votingID] = voting;
    }

    return ResponseCode.success;
  }

  Future<ResponseCode> loadVoting(int votingID) async {
    ApiResponse<Voting> loadVoting = await _votingApi.loadSingleVoting(_relatedCalendarID, votingID);
    Voting? voting = loadVoting.value;

    if (loadVoting.code != ResponseCode.success) {
      return loadVoting.code;
    } else if (voting == null) {
      return ResponseCode.unknown;
    }

    _votingMap[voting.votingID] = voting;

    return ResponseCode.success;
  }

  Future<ResponseCode> createVoting(String title, bool multipleChoice, bool abstentionAllowed, List<NewChoice> choices) async {
    ApiResponse<int> createVoting = await _votingApi.createVoting(_relatedCalendarID, CreateVotingRequest(title, multipleChoice, abstentionAllowed, choices));
    int? newVotingID = createVoting.value;

    if (createVoting.code != ResponseCode.success) {
      return createVoting.code;
    } else if (newVotingID == null) {
      return ResponseCode.unknown;
    }

    return await loadVoting(newVotingID);
  }

  Future<ResponseCode> removeVoting(int votingID) async {
    ResponseCode deleteVoting = await _votingApi.deleteVoting(_relatedCalendarID, votingID);

    if (deleteVoting != ResponseCode.success) {
      return deleteVoting;
    }

    _votingMap.remove(votingID);

    return ResponseCode.success;
  }

  Future<ResponseCode> vote(int votingID, List<int> votes) async {
    ResponseCode vote = await _votingApi.vote(_relatedCalendarID, votingID, VoteRequest(votes));

    if (vote != ResponseCode.success) {
      return vote;
    }

    return await loadVoting(votingID);
  }

  void _resetControllerState() {
    _votingMap.clear();
    _isInitialized = false;
  }
}