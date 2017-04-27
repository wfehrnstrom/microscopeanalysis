classdef Displacement < Operation
    %VIDPLAY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private) 
        vid_src;
        axes;
        error_tag;
        pixel_precision;
        max_displacement;
        template; rect; xtemp; ytemp;
        current_frame;
        table;
        img_cover;
        pause_button;
        table_data;
        stop_check_callback = @check_stop;
        im;
    end

    properties (SetAccess = public)
        pause_bool;
        inputs = {};
        outputs = containers.Map('KeyType','char','ValueType','int32');
        valid;
    end
    
    properties (Constant)
        rx_data = {};
        name = 'Displacement';
        insertion_type = 'end';
    end

    methods
        function obj = Displacement(src, axes, table, error, img_cover, pause_button, pixel_precision, max_displacement, error_report_handle)
            obj.vid_src = src;
            obj.axes = axes;
            obj.table = table;
            obj.error_tag = error;
            obj.img_cover = img_cover;
            obj.pause_button = pause_button;
            obj.pause_bool = false;
            obj.pixel_precision = str2double(pixel_precision);
            obj.max_displacement = str2double(max_displacement);
            obj.startup();
        end

        %For carrying out one time method calls that should be done before
        %calling of execute
        function startup(obj)
            set(obj.img_cover, 'Visible', 'Off');
            set(obj.pause_button, 'Visible', 'On');
            obj.initialize_algorithm();
            obj.table_data = {'DispX'; 'DispY'};
            obj.im = zeros(obj.vid_src.get_num_pixels());
            obj.im = imshow(obj.im);
        end
        
        function initialize_algorithm(obj)
            obj.current_frame = gather(grab_frame(obj.vid_src, obj));
            [obj.template, obj.rect, obj.xtemp, obj.ytemp] = get_template(obj.current_frame, obj.axes);
        end
        
        function execute(obj)          
              obj.current_frame = grab_frame(obj.vid_src, obj);
              if(strcmp(VideoSource.getSourceType(obj.vid_src), 'file'))
                if(obj.vid_src.gpu_supported)
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement_subpixel_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement);
                else
                    [xoffSet, yoffSet, dispx,dispy,x, y] = meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement);
                end
              else
                if(obj.vid_src.gpu_supported)
                    [xoffSet, yoffSet, dispx,dispy,x, y, ~] = meas_displacement_gpu_array(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.max_displacement);
                else
                    meas_displacement(obj.template,obj.rect,obj.current_frame, obj.xtemp, obj.ytemp, obj.pixel_precision, obj.max_displacement);
                end
              end
              draw_rect(obj.current_frame, obj.im, xoffSet, yoffSet, obj.template, obj.axes);
              updateTable(dispx, dispy, obj.table);
              drawnow;
        end

        function valid = validate(obj, error_tag)
            valid = true;
            if(~FileSystemParser.is_file(obj.vid_src.filepath))
                err = Error(Displacement.name(), 'Not passed a valid path on the filesystem', error_tag);
                valid = false;
            end
            if(~valid_max_displacement(obj))
                err = Error(Displacement.name(), 'Max Displacement too large', error_tag);
                valid = false;
            end
            if(valid)
                set(error_tag, 'Visible', 'Off');
            end
        end

        function valid = valid_max_displacement(obj)
            valid = true;
            if(size(obj.current_frame, 2) < obj.max_displacement || isnan(obj.max_displacement))
                valid = false;
            end 
        end
        
        function valid = valid_pixel_precision(obj)
            valid = true;
            if(isnan(obj.pixel_precision))
                valid = false;
            end
        end
        
        function boolean = paused(obj)
            boolean = (obj.pause_bool || ~obj.goodstate());
        end

        function good = goodstate(obj)
            good = true; %TODO: Implement goodstate
        end

        function pause(obj, handles)
            obj.pause_bool = true;
            set(handles.pause_vid, 'String', 'Resume Video');
        end

        function unpause(obj, handles)
            obj.pause_bool = false;
            set(handles.pause_vid, 'String', 'Pause Video');
        end

        function draw_frame(videoReader, axes)
            frame = step(videoReader);
            imshow(frame, 'Parent', axes);
            drawnow;
        end
        
        function path = get_vid_path(obj)
            path = obj.vid_path;
        end
        
        function color = get_vid_colorspace(obj)
            color = obj.vid_colorspace;    
        end
        
        function pixel_precision = get_pixel_precision(obj)
            pixel_precision = obj.pixel_precision;
        end
        
        function max_displacement = get_max_displacement(obj)
           max_displacement = obj.max_displacement;
        end
        
        function bool = check_stop(obj)
            if(~obj.validate(obj.error_tag))
                bool = true;
            else
                bool = obj.vid_src.finished();
            end
        end
        
        function vid_source = get.vid_src(obj)
            vid_source = obj.vid_src;
        end
        
    end

end

