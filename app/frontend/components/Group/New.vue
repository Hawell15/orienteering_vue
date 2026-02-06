<template>
    <Create ref="create" @save="saveGroup" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Grupa</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveGroup() {
    window.location = "/groups?sorting[direction]=desc";
}
</script>
