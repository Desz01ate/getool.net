using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

namespace getool.net
{
    class Program
    {
        static void Main(string[] args)
        {
            var dir = new DirectoryInfo("..\\ge");
            if (!dir.Exists)
            {
                Console.WriteLine("ge folder not found.");
                return;
            }
            ExtractAllIpfs(dir);
        }

        static void ExtractAllIpfs(DirectoryInfo geDir)
        {
            var currentDir = Directory.GetCurrentDirectory();
            var ipfFiles = geDir.EnumerateFiles("*.ipf");
            Parallel.ForEach(ipfFiles, new ParallelOptions() { MaxDegreeOfParallelism = 8 }, file =>
            {
                Console.WriteLine($"Starting extracting of {file}");
                Console.WriteLine("This may take a while, depending on file size. Please wait.");
                Console.WriteLine("Converting to .zip...");
                Call(Path.Combine(currentDir, "bin", "iz.exe"), file.FullName);
                Console.WriteLine("Extracting .zip");
                var zip = file.FullName.Replace("ipf", "zip");
                Call(Path.Combine(currentDir, "bin", "ez.exe"), zip);
                File.Delete(zip);
                if (Regex.IsMatch(file.Name, @"\d"))
                {
                    var outdir = file.FullName.Replace(".ipf", "");
                    var groupDir = Path.Combine(file.DirectoryName, Regex.Replace(file.Name.Replace(".ipf", ""), @"[\d-]", string.Empty));
                    MoveDirectory(outdir, groupDir);
                }
            });
        }

        static void Call(string toolName, string parameter)
        {
            var psi = new ProcessStartInfo("cmd.exe");
            psi.FileName = toolName;
            psi.Arguments = $"\"{parameter}\"";
            Console.WriteLine(psi.ToString());
            var proc = Process.Start(psi);
            proc.WaitForExit();
        }

        public static void MoveDirectory(string source, string target)
        {
            var sourcePath = source.TrimEnd('\\', ' ');
            var targetPath = target.TrimEnd('\\', ' ');
            var files = Directory.EnumerateFiles(sourcePath, "*", SearchOption.AllDirectories)
                                 .GroupBy(s => Path.GetDirectoryName(s));
            foreach (var folder in files)
            {
                var targetFolder = folder.Key.Replace(sourcePath, targetPath);
                Directory.CreateDirectory(targetFolder);
                foreach (var file in folder)
                {
                    var targetFile = Path.Combine(targetFolder, Path.GetFileName(file));
                    if (File.Exists(targetFile)) File.Delete(targetFile);
                    File.Move(file, targetFile);
                }
            }
            Directory.Delete(source, true);
        }
    }
}
