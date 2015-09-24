Elm.Native.Effects = {};
Elm.Native.Effects.make = function(localRuntime) {

	localRuntime.Native = localRuntime.Native || {};
	localRuntime.Native.Effects = localRuntime.Native.Effects || {};
	if (localRuntime.Native.Effects.values)
	{
		return localRuntime.Native.Effects.values;
	}

	var Task = Elm.Native.Task.make(localRuntime);
	var Utils = Elm.Native.Utils.make(localRuntime);
	var Signal = Elm.Signal.make(localRuntime);
	var List = Elm.Native.List.make(localRuntime);


	var NO_REQUEST = 0;
	var PENDING_REQUEST = 1;
	var state = NO_REQUEST;
	var messageArray = [];


	function batchedSending(address, tickMessages)
	{
		var i = messageArray.length - 1;
		while (i >= 0)
		{
			if (messageArray[i].address === address)
			{
				messageArray[i].tickMessages = messageArray[i].tickMessages.concat(List.toArray(tickMessages));
				break;
			}
			i--;
		}
		if (i < 0)
		{
			messageArray.push({ address: address, tickMessages: List.toArray(tickMessages) });
		}

		switch (state)
		{
			case NO_REQUEST:
				requestAnimationFrame(sendCallback);
				state = PENDING_REQUEST;
				return;
			case PENDING_REQUEST:
				state = PENDING_REQUEST;
		}
	}


	function sendCallback(time)
	{
		switch (state)
		{
			case NO_REQUEST:
				// This state should not be possible. How can there be no
				// request, yet somehow we are actively fulfilling a
				// request?
				throw new Error(
					'Unexpected send callback.\n' +
					'Please report this to <https://github.com/evancz/elm-effects/issues>.'
				);

			case PENDING_REQUEST:
				state = NO_REQUEST;
				send(time);
		}
	}


	function send(time)
	{
		for (var i = messageArray.length; i--; )
		{
			var messages = messageArray[i].tickMessages;
			for (var j = messages.length; j--; )
			{
				messages[j] = messages[j](time);
			}
			Task.perform( A2(Signal.send, messageArray[i].address, List.fromArray(messages)) );
		}
		messageArray = [];
	}


	function requestTickSending(address, tickMessages)
	{
		return Task.asyncFunction(function(callback) {
			batchedSending(address, tickMessages);
			callback(Task.succeed(Utils.Tuple0));
		});
	}


	return localRuntime.Native.Effects.values = {
		requestTickSending: F2(requestTickSending)
	};

};
