classdef Queue < handle
    %QUEUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        %An index of which operations in the Queue need to be checked for
        %whether they should be deleted
        condition_evals;
        %Map of which operations in the queue transfer data to which other
        %functions
        data_transfer_map;
        %number of operations in the queue
        length;
        %the actual contents of the queue
        list;
        %flag indicating whether the queue has finished its chain of
        %execution
        done;
        %flag indicating whether the queue is nominal
        valid;
        %error_report_handle stores a function handle given from scheduler which executes when
        %queue or any object in the queue encounters an error
        error_report_handle;    
    end
    
    properties(Access = public, Constant)
        name = 'Queue';
    end
    
    methods
        %operation_list and data_transfer_map should be a cell arrays
        function obj = Queue(error_handle, operation_list)
            obj.error_report_handle = error_handle;
            obj.length = 0;
            obj.done = false;
            if(nargin > 0)
                for i = 1:length(operation_list)
                    obj.add_to_queue(operation_list{i});
                end
            else
                obj.condition_evals = {};
                obj.data_transfer_map = {};
            end
        end
        
        function add_to_queue(obj, operation)
            obj.length = obj.length + 1;
            %If the object should be inserted at the start of the list
            if(strcmp(operation.insertion_type, 'start'))
                for i = obj.length:1
                    obj.list{i + 1} = obj.list{i};
                end
                obj.list{1} = operation;
                obj.add_to_map(operation, 1);
            %Otherwise, insert it at the end
            else
                obj.list{obj.length} = operation;
                obj.extend_map(operation);
            end
        end
        
        function add_to_map(obj, operation, address_inserted)
            obj.data_transfer_map{address_inserted} = {operation.name, operation.outputs};
        end
        
        function extend_map(obj, operation)
            obj.data_transfer_map{length(obj.data_transfer_map) + 1} = {operation.name, operation.outputs};
        end
        
        function execute(obj)
            for i = 1:obj.length
                if(obj.list{i}.get_num_args_in() <= 0)
                    obj.list{i}.execute();
                else
                    obj.list{i}.execute(obj.list{i}.inputs);
                end
                stopped = obj.list{i}.check_stop();
                if(stopped)
                    obj.list = [obj.list{1:(i - 1)} obj.list{(i + 1):end}];
                    obj.length = length(obj.list);
                    if(obj.length == 0)
                        obj.done = true;
                    end
                end
            end
        end
        
        function bool = finished(obj)
            bool = obj.done;
        end
        
        function delete(obj)
            for i = 1:obj.length
                delete(obj.list{i});
            end
            obj.length = 0;
            delete(obj);
        end
        
        function l = fetch_list(obj)
            l = obj.list;
        end
        
        function report_error(obj, error_msg)
            obj.valid = false;
            msg = strcat(obj.name, ':', error_msg);
            feval(obj.error_report_handle, msg);
        end
    end
    
end

