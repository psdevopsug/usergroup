# DSC and Automated Lab with Jan-Hendrik Peters

## Running the labs

In the folder Tasks there are several different lab files that correspond to the different topics presented during
the meetup. In each lab script you will find multiple regions containing a multiline comment which describes
the desired state. It is your task to develop the necessary DSC code to achieve that goal.

The result of your scripts will automatically be tested through the tests you can find in the Tests directory.
We are using Pester and PowerShell's Abstract Syntax Tree (AST) to examine your code.

You can run all tests either by using ```Invoke-Pester``` or by using the VSCode launch configurations for each task.

## Running the labs with VSCode

Open the folder "code" with VSCode in order to make use of the launch configurations in the subfolder .vscode - these
allow you to simply select the lab you want to test.

## Lab 1

Lab 1 will simply test your skills when it comes to creating configurations. The first task is simply configuring a single built-in resource.
Task 2 will require you to use community resources in order to succeed. You will also learn about dependencies.

## Lab 2

This lab deals with configuration data - the lab should take you between 15 and 45 minutes, depending on your level of knowledge with DSC.

## Lab 3

This lab connects a system to Azure Automation DSC (or another pull server).

## Lab 4

This lab was intended to be run on a lab VM running Server 1803 or 2019 and would configure the DSC pull server with native SQL reporting.
