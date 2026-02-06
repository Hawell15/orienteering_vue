<template>
    <Create ref="create" @save="saveRunner" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Sportiv</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveRunner() {
    window.location = "/runners?sorting[direction]=desc";
}
</script>
