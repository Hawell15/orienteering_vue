<template>
    <Create @save="saveCategory" />
</template>
<script setup>
    import Create from './Create.vue'

    function saveCategory() {
         window.location = "/categories?sorting[direction]=desc";
    }
</script>
