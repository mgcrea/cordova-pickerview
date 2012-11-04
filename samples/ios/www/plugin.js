
var plugin = {

    createBasic: function() {
        var slots = [
            {name: 'foo', value: 'baz', data: [
                {value: 'foo', text: 'Displayed Foo'},
                {value: 'bar', text: 'Displayed Bar'},
                {value: 'baz', text: 'Displayed Baz'}
            ]}
        ];
        window.plugins.pickerView.create(slots, {title: 'Title'}, function(selectedValues, buttonIndex) {
            var args = Array.prototype.slice.call(arguments, 0);
            console.log("actionSheet.createComplex:" + JSON.stringify(args));
        });
    },

    createComplex: function() {
        var slots = [
            {name : 'limit_speed', title: 'Speed', data : [
                {text: '50 KB/s', value: 50},
                {text: '100 KB/s', value: 100},
                {text: '200 KB/s', value: 200},
                {text: '300 KB/s', value: 300}
            ]},
            {name : 'road_type', title: 'Road', data : [
                {text: 'Highway', value: 50},
                {text: 'Town', value: 100},
                {text: 'City', value: 200},
                {text: 'Depart', value: 300}
            ]}
        ];

        var options = {
            style: 'black-opaque',
            doneButtonLabel: 'OK',
            cancelButtonLabel: 'Annuler',
            sourceRect: [100.0, 100.0, 20.0, 20.0], // iPad
            arrowDirection: 'up' // iPad
        };

        window.plugins.pickerView.create(slots, options, function(selectedValues, buttonIndex) {
            var args = Array.prototype.slice.call(arguments, 0);
        });

        setTimeout(function() {
            window.plugins.pickerView.setValue({limit_speed: 100, road_type: 300}, {animated: true});
        }, 1000);
    }

};

