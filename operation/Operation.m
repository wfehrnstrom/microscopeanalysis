classdef (Abstract) Operation < handle
    %OPERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        %The value checked for the conditional, either a function to call
        %to check, or a number, specifying a preset number of iterations
        %the operation will execute
        stop_check_callback = @check_stop;    
        %names of operations that this operation object will receive data
        %from, and what it will receive from them.  Stored in the format:
        %{name_of_operation_receiving_from, {params_to_receive}}
        %in a given queue.  Information is not passed from queue to queue
        %in the scheduler
        rx_data;
        %insertion_type controls where this operation should be inserted in
        %a queue.  Currently, there are no guarantees as to a specific
        %index at which an operation will be placed.  This is intended as
        %an enumeration, where the possible values are {start, end}
        insertion_type;
        %inputs is a simple cell array of all the inputs collected from
        %available operations sharing the same queue.  These inputs will be
        %passed to the operation's execute function
        inputs;
        %error_report_handle stores the handle that should execute when
        %this operation encounters an error and cannot continue, this
        %handle will be from a function defined in queue.
        error_report_handle;
    end
    
    properties(Access = public, Abstract)
        %output_map is a map containing key:value pairs of the form "name
        %of the output variable"(of type string):value of the
        %variable(varies).  You, as a coder may pick and choose which
        %values outputted from execute() may be sent, and documented by the
        %output map.
        outputs;
        %indicates whether the object is in a good state or not
        valid;
    end
    
    properties(Access = public, Abstract, Constant)
        %Name of the operation
        name;
    end

    methods(Abstract)
        %METHOD: check_stop
        %Used to configure the operation's stop condition in the queue, which in turn determines whether the operation
        %should remain in the queue after it executes.
        %Should the operation only execute once?  If so, it has
        %a single_shot stop type
        %Should it execute a certain number of times? If so, it has a repeat
        %stop type, and the stop trigger specified should be some number of
        %times for the operation to execute
        %Should it stop on some other conditional? If so, it has a trigger
        %stop type, and you must provide the handle of the function to call
        %that the queue will evaluate each time after the operation executes
        %Params: obj
        %condition_type: {'repeat', 'trigger', 'single_shot'}.  Configures
        %how the container queue of this operation should assess whether it
        %should remain in the queue for another execution, or remove it
        %stop_trigger: can either be not passed, a number, or a function
        %handle depending on the condition_type
        bool = check_stop(obj)
        
        %METHOD: execute
        %The most important method of the operational design model
        %implemented for this GUI.  This method specifies what operation
        %the operation object will perform when called in a given queue.
        %This could be displaying an image, retrieving data from a sensor,
        %or logging a value, but the execute method code must be consistent
        %for a given operation type.  Whether it takes argument(s) does not
        %have to be consistent for any given operation.
        execute(obj, argsin);
    end
    
    methods
        
        function report_error(obj, error)
            obj.valid = false;
            error_msg = strcat(obj.name, '_operation: ', error);
            try
                feval(obj.error_report_handle);
            catch(feval(obj.error_report_handle, error_msg))
                disp('ERROR_REPORT_HANDLE FAILED TO EXECUTE');
            end
        end
        
        function val = get.stop_check_callback(obj)
            val = obj.stop_check_callback;
        end
        
        function insert_type = get.insertion_type(obj)
            insert_type = obj.insertion_type;
        end
        
        function rx = get.rx_data(obj)
            rx = obj.rx_data;
        end

        function args_out = get_num_args_out(obj)
           args_out = length(obj.outputs);
        end
        
        function args_in = get_num_args_in(obj)
           args_in = length(obj.inputs);
        end
    end
    
end

