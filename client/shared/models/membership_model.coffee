BaseModel = require 'shared/record_store/base_model'
AppConfig = require 'shared/services/app_config'

module.exports = class MembershipModel extends BaseModel
  @singular: 'membership'
  @plural: 'memberships'
  @indices: ['id', 'userId', 'groupId']
  @searchableFields: ['userName', 'userUsername']
  @serializableAttributes: AppConfig.permittedParams.membership

  relationships: ->
    @belongsTo 'group'
    @belongsTo 'user'
    @belongsTo 'inviter', from: 'users'

  userName: ->
    @user().name

  userUsername: ->
    @user().username

  userEmail: ->
    @user().email

  groupName: ->
    @group().name

  saveVolume: (volume, applyToAll = false) ->
    @remote.patchMember(@keyOrId(), 'set_volume',
      volume: volume
      apply_to_all: applyToAll
      unsubscribe_token: @user().unsubscribeToken).then =>
      if applyToAll
        _.each @user().allThreads(), (thread) ->
          thread.update(discussionReaderVolume: null)
        _.each @user().memberships(), (membership) ->
          membership.update(volume: volume)
      else
        _.each @group().discussions(), (discussion) ->
          discussion.update(discussionReaderVolume: null)

  resend: ->
    @remote.postMember(@keyOrId(), 'resend').then =>
      @resent = true

  isMuted: ->
    @volume == 'mute'

  beforeRemove: ->
    _.invoke(@recordStore.events.find('eventable.type': 'membership', 'eventable.id': @id), 'remove')
