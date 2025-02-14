function impedance_database_summary(IMPRING,aperture_flag,pie_flag,impedance_flag)
%% Produce summary statistics for impedance database
% aperture_flag - plot apertures
% pie_flag - plot pie charts
% impedance_flag - plot impedance

    %% Resistive wall statistics

    % Get all materials in database
    materials = unique(atgetfieldvalues(IMPRING,'Material'));

    % Get total length of each material
    material_lengths = zeros(length(materials),1);

    for i = 1:length(materials)

        elements = findcells(IMPRING,'Material',materials{i});
        material_lengths(i) = sum(atgetfieldvalues(IMPRING,elements,'Length'));

    end

    % Total length
    total_length = sum(material_lengths);

    % Print out
    fprintf('Resistive wall:\n')
    for i = 1:length(materials)
        fprintf('%s: %.5f m (%.2f%%)\n',materials{i},material_lengths(i),(material_lengths(i)./total_length).*100)
    end
    fprintf('Total length = %f\n',total_length)
    fprintf('\n')

    %% Apertures
    
    if aperture_flag

        color=get(gca,'ColorOrder');

        % Find position of entrance of each element
        s = findspos(IMPRING,1:length(IMPRING))';
        lengths = atgetfieldvalues(IMPRING,'Length');

        apertures = atgetfieldvalues(IMPRING,'Apertures');
        apertures  = cat(1,apertures{:});
        entrance_apertures  = apertures(1:2:end,:);
        exit_apertures  = apertures(2:2:end,:);

        figure(1)
        plot(s,entrance_apertures(:,1)*1e3,'.-','Color',color(1,:))
        hold on
        plot(s+lengths,exit_apertures(:,1)*1e3,'.-','Color',color(1,:))
        plot(s,entrance_apertures(:,2)*1e3,'.-','Color',color(1,:))
        plot(s+lengths,exit_apertures(:,2)*1e3,'.-','Color',color(1,:))
        hold off
        xlabel('Position [m]')
        ylabel('Horizontal aperture [mm]')
        xlim([0,total_length])
        %xlim([0,total_length./6])

        figure(2)
        plot(s,entrance_apertures(:,3)*1e3,'.-','Color',color(1,:))
        hold on
        plot(s+lengths,exit_apertures(:,3)*1e3,'.-','Color',color(1,:))
        plot(s,entrance_apertures(:,4)*1e3,'.-','Color',color(1,:))
        plot(s+lengths,exit_apertures(:,4)*1e3,'.-','Color',color(1,:))
        hold off
        xlabel('Position [m]')
        ylabel('Vertical aperture [mm]')
        xlim([0,total_length])
        %xlim([0,total_length./6])
    end

    %% Geometric impedance statistics

    % Get all components in database
    components = unique(atgetfieldvalues(IMPRING,'FamName'));

    % Get number of components
    component_amount = zeros(length(components),1);

    for i = 1:length(components)

        elements = findcells(IMPRING,'FamName',components{i});
        component_amount(i) = length(elements);

    end

    % Print out
    fprintf('Number of components:\n')
    for i = 1:length(components)
        fprintf('%s: %d \n',components{i},component_amount(i))
    end
    fprintf('\n')

    %% Plot pie charts
    
    if pie_flag

        % Find classes
        classes = unique(atgetfieldvalues(IMPRING,'Class'));

        % Get total k factors per class
        tot_k_factors = zeros(length(classes),3);

        for i = 1:length(classes)

            elements = findcells(IMPRING,'Class',classes{i});    
            k_factors = cell2mat(atgetfieldvalues(IMPRING,elements,'Geom_k_factors'));    
            tot_k_factors(i,:) = tot_k_factors(i,:) + sum(abs(k_factors));

        end

        labels = classes;

        figure(3)
        pie(tot_k_factors(:,1))
        legend(labels,'Location','NorthWestOutside')
        title('Horizontal kick factor')
        colormap('lines')

        figure(4)
        pie(tot_k_factors(:,2))
        legend(labels,'Location','NorthWestOutside')
        title('Vertical kick factor')
        colormap('lines')

        figure(5)
        pie(tot_k_factors(:,3))
        legend(labels,'Location','NorthWestOutside')
        title('Loss factor')
        colormap('lines')
        
    end

    %% Plot cumulative impedance
    
    if impedance_flag

        % Interpolation parameters
        sampling_freq = linspace(0,35,1e4)'; %Units are in GHz
    
        % Find classes
        classes = unique(atgetfieldvalues(IMPRING,'Class'));
        labels = classes;

        % Get impedance per class
        hor_real_impedance = zeros(length(sampling_freq),length(classes));
        hor_imag_impedance = zeros(length(sampling_freq),length(classes));
        ver_real_impedance = zeros(length(sampling_freq),length(classes));
        ver_imag_impedance = zeros(length(sampling_freq),length(classes));
        lon_real_impedance = zeros(length(sampling_freq),length(classes));
        lon_imag_impedance = zeros(length(sampling_freq),length(classes));

        for i = 1:length(classes)

            elements = findcells(IMPRING,'Class',classes{i});

            for j = 1:length(elements)

                if ~isempty(IMPRING{elements(j)}.Geom_impedance_files)

                    % Import horizontal impedance data
                    hor_data = importdata(IMPRING{elements(j)}.Geom_impedance_files{1}).data;

                    real_impedance = interp1(hor_data(:,1),hor_data(:,2),sampling_freq,'linear',0);
                    imag_impedance = interp1(hor_data(:,1),hor_data(:,3),sampling_freq,'linear',0);

                    hor_real_impedance(:,i) = hor_real_impedance(:,i) + real_impedance;
                    hor_imag_impedance(:,i) = hor_imag_impedance(:,i) + imag_impedance;

                    % Import vertical impedance data
                    ver_data = importdata(IMPRING{elements(j)}.Geom_impedance_files{2}).data;

                    real_impedance = interp1(ver_data(:,1),ver_data(:,2),sampling_freq,'linear',0);
                    imag_impedance = interp1(ver_data(:,1),ver_data(:,3),sampling_freq,'linear',0);

                    ver_real_impedance(:,i) = ver_real_impedance(:,i) + real_impedance;
                    ver_imag_impedance(:,i) = ver_imag_impedance(:,i) + imag_impedance; 

                    % Import longitudinal impedance data
                    lon_data = importdata(IMPRING{elements(j)}.Geom_impedance_files{3}).data;

                    real_impedance = interp1(lon_data(:,1),lon_data(:,2),sampling_freq,'linear',0);
                    imag_impedance = interp1(lon_data(:,1),lon_data(:,3),sampling_freq,'linear',0);

                    lon_real_impedance(:,i) = lon_real_impedance(:,i) + real_impedance;
                    lon_imag_impedance(:,i) = lon_imag_impedance(:,i) + imag_impedance;               

                end

            end

        end

        figure(6)
        subplot(211)
        area(sampling_freq,-hor_real_impedance.*1e3.*1e-3,'LineStyle','None')
        ylabel('Re Z_x [k\Omega/m]')
        xlabel('Frequency [GHz]')
        legend(labels)

        subplot(212)
        area(sampling_freq,-hor_imag_impedance.*1e3.*1e-3,'LineStyle','None')
        ylabel('Im Z_x [k\Omega/m]')
        xlabel('Frequency [GHz]')
        legend(labels)

        figure(7)
        subplot(211)
        area(sampling_freq,-ver_real_impedance.*1e3.*1e-3,'LineStyle','None')
        ylabel('Re Z_y [k\Omega/m]')
        xlabel('Frequency [GHz]')
        legend(labels)

        subplot(212)
        area(sampling_freq,-ver_imag_impedance.*1e3.*1e-3,'LineStyle','None')
        ylabel('Im Z_y [k\Omega/m]')
        xlabel('Frequency [GHz]')
        legend(labels)

        figure(8)
        subplot(211)
        area(sampling_freq,lon_real_impedance.*1e-3,'LineStyle','None')
        ylabel('Re Z_L [k\Omega]')
        xlabel('Frequency [GHz]')
        legend(labels)

        subplot(212)
        area(sampling_freq,lon_imag_impedance.*1e-3,'LineStyle','None')
        ylabel('Im Z_L [k\Omega]')
        xlabel('Frequency [GHz]')
        legend(labels)
               
    end


end


    
