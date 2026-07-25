package body Validation.Versions is

   function Image (V : Semantic_Version) return String is
      function Raw (C : Version_Component) return String is
         S : constant String := Version_Component'Image (C);
      begin
         --  Drop the leading space 'Image inserts for non-negative values.
         return S (S'First + 1 .. S'Last);
      end Raw;
   begin
      return Raw (V.Major) & "." & Raw (V.Minor) & "." & Raw (V.Patch);
   end Image;

   function "<" (Left, Right : Semantic_Version) return Boolean is
   begin
      if Left.Major /= Right.Major then
         return Left.Major < Right.Major;
      elsif Left.Minor /= Right.Minor then
         return Left.Minor < Right.Minor;
      else
         return Left.Patch < Right.Patch;
      end if;
   end "<";

   function "<=" (Left, Right : Semantic_Version) return Boolean is
     (Left < Right or else Left = Right);

end Validation.Versions;
